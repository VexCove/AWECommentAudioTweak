#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${script_dir}/build-relevance.sh"

notes_file="${1:-release-notes.md}"
head_sha="${RELEASE_HEAD_SHA:-${GITHUB_SHA:-HEAD}}"
repository="${GITHUB_REPOSITORY:-$(git config --get remote.origin.url | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')}"
server_url="${GITHUB_SERVER_URL:-https://github.com}"
release_title="${RELEASE_TITLE:-Release}"

feat_file=$(mktemp)
fix_file=$(mktemp)
perf_file=$(mktemp)
refactor_file=$(mktemp)
docs_file=$(mktemp)
style_file=$(mktemp)
chore_file=$(mktemp)
revert_file=$(mktemp)
records_file=$(mktemp)
skip_file=$(mktemp)
net_paths_file=$(mktemp)
net_diff_lines_file=$(mktemp)
entries_file=$(mktemp)
contributors_file=$(mktemp)
trap 'rm -f "$feat_file" "$fix_file" "$perf_file" "$refactor_file" "$docs_file" "$style_file" "$chore_file" "$revert_file" "$records_file" "$skip_file" "$net_paths_file" "$net_diff_lines_file" "$entries_file" "$contributors_file"' EXIT

trim_text() {
    local value=$1

    printf '%s' "$value" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

strip_commit_type_prefix() {
    local subject=$1
    local commit_prefix_regex='^[A-Za-z]+(\([^)]+\))?(!)?[:：][[:space:]]*(.*)$'

    if [[ "$subject" =~ $commit_prefix_regex ]]; then
        subject=${BASH_REMATCH[3]}
    fi

    trim_text "$subject"
}

raw_commit_type() {
    local subject=$1
    local raw_type
    local commit_type_regex='^([A-Za-z]+)(\([^)]+\))?(!)?[:：]'

    if [[ "$subject" =~ $commit_type_regex ]]; then
        raw_type=${BASH_REMATCH[1]}
        printf '%s' "$raw_type" | tr '[:upper:]' '[:lower:]'
        return
    fi

    printf ''
}

canonical_commit_type() {
    local subject=$1
    local raw_type

    raw_type=$(raw_commit_type "$subject")
    case "$raw_type" in
        feat|feature|add)
            printf 'feat'
            return
            ;;
        fix|bug|bugfix)
            printf 'fix'
            return
            ;;
        perf|performance)
            printf 'perf'
            return
            ;;
        refactor)
            printf 'refactor'
            return
            ;;
        docs|doc)
            printf 'docs'
            return
            ;;
        style|format)
            printf 'style'
            return
            ;;
        chore|build|ci|test|merge)
            printf 'chore'
            return
            ;;
        revert)
            printf 'revert'
            return
            ;;
    esac

    case "$subject" in
        Revert\ *|revert:*|revert：*|回滚*|撤销*)
            printf 'revert'
            ;;
        新增*|增加*|添加*|支持*|引入*|实现*)
            printf 'feat'
            ;;
        修复*|解决*|恢复*|纠正*|*修复*)
            printf 'fix'
            ;;
        性能*|提速*|加速*|*性能*优化*|*速度*优化*|*加载*优化*)
            printf 'perf'
            ;;
        重构*|简化*|清理*|整理*|调整*|优化*|完善*)
            printf 'refactor'
            ;;
        文档*|README*|readme*|注释*|更新版本号*|版本更新*)
            printf 'docs'
            ;;
        格式*|格式化*)
            printf 'style'
            ;;
        *)
            printf 'chore'
            ;;
    esac
}

version_summary_for_commit() {
    local hash=$1
    local previous_version
    local current_version

    previous_version=$(
        git show "${hash}^:control" 2>/dev/null |
            awk -F': ' '$1 == "Version" { print $2; exit }' || true
    )
    current_version=$(
        git show "${hash}:control" 2>/dev/null |
            awk -F': ' '$1 == "Version" { print $2; exit }' || true
    )

    if [[ -n "$current_version" && "$previous_version" != "$current_version" ]]; then
        if [[ -n "$previous_version" ]]; then
            printf '更新版本号：`%s` → `%s`' "$previous_version" "$current_version"
        else
            printf '设置版本号为 `%s`' "$current_version"
        fi
    fi
}

keyword_content_for_subject() {
    local subject=$1

    case "$subject" in
        *Release*|*release*)
            printf 'Release 更新日志'
            ;;
        *dylib*|*Dylib*)
            printf 'dylib 发布产物'
            ;;
        *Deb*|*deb*)
            printf 'Deb 构建产物'
            ;;
        *工作流*|*Actions*|*actions*)
            printf '自动打包工作流'
            ;;
    esac
}

summarize_commit_title() {
    local hash=$1
    local subject=$2
    local commit_type=$3
    local content
    local version_summary
    local revert_regex='^Revert[[:space:]]+"(.*)"$'
    local keyword_content

    if commit_touches_control "$hash"; then
        version_summary=$(version_summary_for_commit "$hash")
        if [[ -n "$version_summary" ]]; then
            printf '%s' "$version_summary"
            return
        fi
    fi

    if commit_touches_path "$hash" "Makefile" &&
       ! commit_touches_direct_build_path "$hash"; then
        printf '调整 Deb 构建配置'
        return
    fi

    content=$(strip_commit_type_prefix "$subject")
    content=$(printf '%s' "$content" | sed -E 's/[[:space:]。；;，,]+$//')

    if [[ "$commit_type" == "revert" && "$content" =~ $revert_regex ]]; then
        content=$(strip_commit_type_prefix "${BASH_REMATCH[1]}")
    fi

    keyword_content=$(keyword_content_for_subject "$subject")
    if [[ -n "$keyword_content" ]]; then
        content=$keyword_content
    fi

    case "$commit_type" in
        feat)
            content=$(printf '%s' "$content" | sed -E 's/^(新增|增加|添加|支持|引入|实现|优化)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '新增%s' "${content:-插件功能}"
            ;;
        fix)
            content=$(printf '%s' "$content" | sed -E 's/^(兜底修复|修复|解决|恢复|纠正|修改|调整)[[:space:]:：]*//; s/的问题$//')
            content=$(printf '%s' "$content" | sed -E 's/不生效/生效异常/g; s/失效/异常/g; s/无法/不能/g')
            content=$(trim_text "$content")
            printf '修正%s' "${content:-已知问题}"
            ;;
        perf)
            content=$(printf '%s' "$content" | sed -E 's/^(性能优化|优化|提升|改善|提速|加速)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '优化%s' "${content:-运行性能}"
            ;;
        refactor)
            content=$(printf '%s' "$content" | sed -E 's/^(重构|简化|清理|整理|调整|优化|完善)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '整理%s' "${content:-代码结构}"
            ;;
        docs)
            content=$(printf '%s' "$content" | sed -E 's/^(文档|更新|修改|补充)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '更新%s' "${content:-文档说明}"
            ;;
        style)
            content=$(printf '%s' "$content" | sed -E 's/^(格式化|格式|规范|调整)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '规范%s' "${content:-代码格式}"
            ;;
        revert)
            content=$(printf '%s' "$content" | sed -E 's/^(回滚|撤销|取消)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '回滚%s' "${content:-上一项变更}"
            ;;
        *)
            content=$(printf '%s' "$content" | sed -E 's/^(杂项|其他|更新|调整|同步)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '调整%s' "${content:-构建与维护项}"
            ;;
    esac
}

section_file_for_type() {
    case "$1" in
        feat) printf '%s' "$feat_file" ;;
        fix) printf '%s' "$fix_file" ;;
        perf) printf '%s' "$perf_file" ;;
        refactor) printf '%s' "$refactor_file" ;;
        docs) printf '%s' "$docs_file" ;;
        style) printf '%s' "$style_file" ;;
        revert) printf '%s' "$revert_file" ;;
        *) printf '%s' "$chore_file" ;;
    esac
}

write_net_build_paths() {
    local before=$1
    local after=$2
    local path
    local makefile_changed=false

    while IFS= read -r path; do
        [[ -n "$path" ]] || continue

        if is_direct_build_path "$path"; then
            printf '%s\n' "$path"
            continue
        fi

        if [[ "$path" == "Makefile" ]]; then
            makefile_changed=true
        fi
    done < <(git diff --name-only "$before" "$after")

    if [[ "$makefile_changed" == true ]] &&
       makefile_affects_build "$before" "$after"; then
        printf 'Makefile\n'
    fi
}

commit_intersects_net_build_paths() {
    local hash=$1
    local path

    if [[ ! -s "$net_paths_file" ]]; then
        return 1
    fi

    while IFS= read -r path; do
        [[ -n "$path" ]] || continue

        if grep -Fxq -- "$path" "$net_paths_file"; then
            return 0
        fi
    done < <(git diff-tree --root --no-commit-id --name-only -r "$hash")

    return 1
}

write_diff_signal_lines() {
    local before=$1
    local after=$2

    git diff --unified=0 --no-ext-diff "$before" "$after" |
        awk '
            function diff_path(line) {
                sub(/^[+-]{3}[[:space:]]+/, "", line)
                sub(/^[ab]\//, "", line)
                return line
            }

            /^diff --git / { next }
            /^index / { next }
            /^new file mode / { next }
            /^deleted file mode / { next }
            /^old mode / { next }
            /^new mode / { next }
            /^--- / {
                old_path = diff_path($0)
                next
            }
            /^\+\+\+ / {
                new_path = diff_path($0)
                next
            }
            /^@@ / { next }
            /^[+-]/ {
                prefix = substr($0, 1, 1)
                line = substr($0, 2)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                if (line == "" || line ~ /^[{}()[\];,]+$/) next
                path = prefix == "+" ? new_path : old_path
                print prefix path "\t" line
            }
        '
}

commit_overlaps_net_diff() {
    local hash=$1
    local parent
    local signal_file
    local line
    local matched=false

    parent=$(git rev-parse "${hash}^" 2>/dev/null || git hash-object -t tree /dev/null)
    signal_file=$(mktemp)
    write_diff_signal_lines "$parent" "$hash" > "$signal_file"

    if [[ ! -s "$signal_file" ]]; then
        rm -f "$signal_file"
        return 0
    fi

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        if grep -Fxq -- "$line" "$net_diff_lines_file"; then
            matched=true
            break
        fi
    done < "$signal_file"

    rm -f "$signal_file"
    [[ "$matched" == true ]]
}

feature_group_key() {
    local hash=$1
    local title=$2
    local subject=$3
    local combined
    local normalized

    combined="${title} ${subject}"
    case "$combined" in
        *快捷倍速*|*长按倍速*|*倍速设置*)
            printf 'feature:quick-speed'
            return
            ;;
        *AI*图标*|*AI*按钮*|*ai*图标*|*ai*按钮*)
            printf 'feature:ai-icon'
            return
            ;;
        *评论栏*加号*|*加号*定位按钮*|*定位按钮*|*POI*按钮*|*poi*按钮*)
            printf 'feature:comment-toolbar-layout'
            return
            ;;
        *语音试听*|*试听*后端*|*试听报错*)
            printf 'feature:voice-preview'
            return
            ;;
        *沙盒文件*|*文件管理*)
            printf 'feature:file-manager'
            return
            ;;
        *语音替换*|*替换互斥*|*设置替换*)
            printf 'feature:audio-replace'
            return
            ;;
        *发布日志*|*更新日志*|*Release*日志*|*release*日志*)
            printf 'feature:release-notes'
            return
            ;;
        *自动打包*|*打包工作流*|*Build*deb*|*build*deb*)
            printf 'feature:package-workflow'
            return
            ;;
        *dylib*|*Dylib*)
            printf 'feature:dylib-artifact'
            return
            ;;
        *版本号*|*版本更新*)
            printf 'feature:version'
            return
            ;;
    esac

    normalized=$(printf '%s' "$title" |
        sed -E 's/^(新增|修正|优化|整理|更新|规范|回滚|调整)//')
    normalized=$(printf '%s' "$normalized" |
        sed -E 's/(的问题|问题|异常|逻辑|代码|配置|功能|设置|选项|状态)$//')
    normalized=$(printf '%s' "$normalized" |
        tr -d '[:space:]' |
        sed -E 's/[[:punct:]，。；：“”"'\''（）()、]//g')

    if [[ ${#normalized} -ge 6 ]]; then
        printf 'title:%s' "$normalized"
        return
    fi

    printf 'commit:%s' "$hash"
}

feature_group_label() {
    local group_key=$1

    case "$group_key" in
        feature:quick-speed) printf '快捷倍速' ;;
        feature:ai-icon) printf 'AI 图标' ;;
        feature:comment-toolbar-layout) printf '评论栏按钮布局' ;;
        feature:voice-preview) printf '语音试听' ;;
        feature:file-manager) printf '沙盒文件管理' ;;
        feature:audio-replace) printf '语音替换' ;;
        feature:release-notes) printf '发布日志' ;;
        feature:package-workflow) printf '自动打包工作流' ;;
        feature:dylib-artifact) printf 'dylib 发布产物' ;;
        feature:version) printf '版本号' ;;
    esac
}

reverted_commit_hash() {
    local hash=$1
    local target_hash
    local resolved_hash

    target_hash=$(
        git show -s --format=%B "$hash" |
            sed -nE 's/^This reverts commit ([0-9a-fA-F]{7,40})\.$/\1/p' |
            head -n 1
    )

    if [[ -z "$target_hash" ]]; then
        return
    fi

    resolved_hash=$(git rev-parse --verify "${target_hash}^{commit}" 2>/dev/null || true)
    printf '%s' "${resolved_hash:-$target_hash}"
}

reverted_subject_from_title() {
    local subject=$1
    local revert_regex='^Revert[[:space:]]+"(.*)"$'

    if [[ "$subject" =~ $revert_regex ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return
    fi

    case "$subject" in
        回滚*|撤销*|取消*)
            printf '%s' "$subject" | sed -E 's/^(回滚|撤销|取消)[[:space:]:：]*//'
            ;;
    esac
}

normalize_revert_match_text() {
    local value=$1

    value=$(strip_commit_type_prefix "$value")
    value=$(printf '%s' "$value" |
        sed -E 's/^(新增|增加|添加|支持|引入|实现|修复|解决|恢复|纠正|修改|调整|优化|完善|重构|简化|清理|整理)[[:space:]:：]*//')
    value=$(printf '%s' "$value" |
        sed -E 's/(的问题|问题|逻辑|优化|功能|选项|状态)$//')
    value=$(printf '%s' "$value" |
        tr -d '[:space:]' |
        sed -E 's/[[:punct:]，。；：“”"'\''（）()、]//g')

    printf '%s' "$value"
}

record_contains_hash() {
    local target_hash=$1

    awk -F $'\t' -v target="$target_hash" '
        $1 == target || index($1, target) == 1 || index(target, $1) == 1 {
            found = 1
        }
        END {
            exit found ? 0 : 1
        }
    ' "$records_file"
}

mark_skip_pair() {
    local revert_hash=$1
    local target_hash=$2

    printf '%s\n%s\n' "$revert_hash" "$target_hash" >> "$skip_file"
}

detect_same_range_reverts() {
    local hash
    local subject
    local commit_type
    local target_hash
    local target_subject
    local target_key
    local candidate_hash
    local candidate_subject
    local candidate_type
    local candidate_key

    while IFS=$'\t' read -r hash subject commit_type; do
        [[ -n "$hash" ]] || continue
        [[ "$commit_type" == "revert" ]] || continue

        target_hash=$(reverted_commit_hash "$hash")
        if [[ -n "$target_hash" ]] && record_contains_hash "$target_hash"; then
            mark_skip_pair "$hash" "$target_hash"
            continue
        fi

        target_subject=$(reverted_subject_from_title "$subject")
        target_key=$(normalize_revert_match_text "$target_subject")
        if [[ -z "$target_key" || "${#target_key}" -lt 6 ]]; then
            continue
        fi

        while IFS=$'\t' read -r candidate_hash candidate_subject candidate_type; do
            [[ -n "$candidate_hash" ]] || continue
            [[ "$candidate_hash" == "$hash" ]] && continue

            candidate_key=$(normalize_revert_match_text "$candidate_subject")
            if [[ -n "$candidate_key" && "$candidate_key" == "$target_key" ]]; then
                mark_skip_pair "$hash" "$candidate_hash"
                break
            fi
        done < "$records_file"
    done < "$records_file"
}

commit_is_skipped() {
    local hash=$1

    grep -Fxq "$hash" "$skip_file"
}

commit_touches_control() {
    local hash=$1

    commit_touches_path "$hash" "control"
}

latest_release_tag() {
    local latest_tag

    if ! command -v gh >/dev/null 2>&1 ||
       [[ -z "${GH_TOKEN:-}" || -z "$repository" ]]; then
        return
    fi

    latest_tag=$(gh api "repos/${repository}/releases/latest" \
        --jq '.tag_name // empty' 2>/dev/null || true)
    printf '%s' "$latest_tag"
}

tag_points_to_commit() {
    local tag=$1

    git cat-file -e "${tag}^{commit}" 2>/dev/null
}

ensure_release_tag_available() {
    local tag=$1

    if tag_points_to_commit "$tag"; then
        return 0
    fi

    git fetch --force --no-tags origin "refs/tags/${tag}:refs/tags/${tag}" \
        >/dev/null 2>&1 || return 1
    tag_points_to_commit "$tag"
}

contributor_for_commit() {
    local hash=$1
    local author_email
    local github_login
    local noreply_with_id='^[0-9]+\+([^@]+)@users\.noreply\.github\.com$'
    local noreply_plain='^([^@]+)@users\.noreply\.github\.com$'

    if command -v gh >/dev/null 2>&1 &&
       [[ -n "${GH_TOKEN:-}" && -n "$repository" ]]; then
        github_login=$(gh api "repos/${repository}/commits/${hash}" \
            --jq '.author.login // .committer.login // empty' 2>/dev/null || true)
        if [[ -n "$github_login" ]]; then
            printf '@%s' "$github_login"
            return
        fi
    fi

    author_email=$(git show -s --format=%ae "$hash")

    if [[ "$author_email" =~ $noreply_with_id ]]; then
        printf '@%s' "${BASH_REMATCH[1]}"
        return
    fi
    if [[ "$author_email" =~ $noreply_plain ]]; then
        printf '@%s' "${BASH_REMATCH[1]}"
        return
    fi
}

record_contributor_for_commit() {
    local hash=$1
    local contributor

    contributor=$(contributor_for_commit "$hash")
    if [[ -n "$contributor" ]] &&
       ! grep -Fxq -- "$contributor" "$contributors_file"; then
        printf '%s\n' "$contributor" >> "$contributors_file"
    fi
}

write_grouped_entries() {
    awk -F $'\t' -v server_url="$server_url" -v repository="$repository" '
        function type_rank(type) {
            if (type == "feat") return 1
            if (type == "fix") return 2
            if (type == "perf") return 3
            if (type == "refactor") return 4
            if (type == "docs") return 5
            if (type == "style") return 6
            if (type == "chore") return 7
            if (type == "revert") return 8
            return 9
        }

        function has_type(key, type) {
            return index("\034" types[key] "\034", "\034" type "\034") > 0
        }

        function add_type(key, type) {
            if (!has_type(key, type)) {
                types[key] = types[key] (types[key] == "" ? "" : "\034") type
            }
        }

        function commit_link(hash) {
            return "[`" substr(hash, 1, 8) "`](" server_url "/" repository "/commit/" hash ")"
        }

        function grouped_title(type, label) {
            if (type == "feat") return "新增" label "相关功能"
            if (type == "fix") return "修正" label "相关问题"
            if (type == "perf") return "优化" label "相关性能"
            if (type == "refactor") return "整理" label "相关代码"
            if (type == "docs") return "更新" label "相关说明"
            if (type == "style") return "规范" label "相关格式"
            if (type == "revert") return "回滚" label "相关改动"
            return "调整" label "相关改动"
        }

        NF >= 5 {
            key = $1
            title = $2
            type = $3
            hash = $4
            label = $5

            if (!(key in seen)) {
                seen[key] = 1
                order[++count] = key
                primary_type[key] = type
                title_for[key] = title
                label_for[key] = label
            } else if (type_rank(type) < type_rank(primary_type[key])) {
                primary_type[key] = type
                title_for[key] = title
            }

            item_count[key]++
            add_type(key, type)
            links[key] = links[key] (links[key] == "" ? "" : ", ") commit_link(hash)
        }

        END {
            for (i = 1; i <= count; i++) {
                key = order[i]
                type_count = split(types[key], type_parts, "\034")
                tags = ""
                for (j = 1; j <= type_count; j++) {
                    if (type_parts[j] == "") continue
                    tags = tags (tags == "" ? "" : " ") "`" type_parts[j] "`"
                }
                title = title_for[key]
                if (item_count[key] > 1 && label_for[key] != "") {
                    title = grouped_title(primary_type[key], label_for[key])
                }
                print primary_type[key] "\t- " tags " **" title "** (" links[key] ")"
            }
        }
    ' "$entries_file" |
        while IFS=$'\t' read -r primary_type entry; do
            [[ -n "$primary_type" && -n "$entry" ]] || continue
            printf '%s\n' "$entry" >> "$(section_file_for_type "$primary_type")"
        done
}

previous_tag=$(latest_release_tag)
if [[ -n "$previous_tag" ]] &&
   ! ensure_release_tag_available "$previous_tag"; then
    previous_tag=""
fi

if [[ -z "$previous_tag" ]]; then
    previous_tag=$(git tag --list 'AWECommentAudioTweak_*' --sort=-version:refname | head -n 1)
fi

if [[ -n "$previous_tag" ]] &&
   ! tag_points_to_commit "$previous_tag"; then
    previous_tag=""
fi

if [[ -n "$previous_tag" ]]; then
    commit_range="${previous_tag}..${head_sha}"
    release_base_ref="$previous_tag"
elif [[ -n "${PUSH_BEFORE:-}" && "$PUSH_BEFORE" != "$zero_sha" ]] &&
     git cat-file -e "${PUSH_BEFORE}^{commit}" 2>/dev/null; then
    commit_range="${PUSH_BEFORE}..${head_sha}"
    release_base_ref="$PUSH_BEFORE"
else
    if git rev-parse "${head_sha}^" >/dev/null 2>&1; then
        release_base_ref="${head_sha}^"
        commit_range="${release_base_ref}..${head_sha}"
    else
        release_base_ref=$(git hash-object -t tree /dev/null)
        commit_range="$head_sha"
    fi
fi

write_net_build_paths "$release_base_ref" "$head_sha" > "$net_paths_file"
write_diff_signal_lines "$release_base_ref" "$head_sha" > "$net_diff_lines_file"

while IFS=$'\t' read -r hash subject; do
    [[ -n "$hash" ]] || continue

    parent_count=$(git rev-list --parents -n 1 "$hash" | awk '{ print NF - 1 }')
    if (( parent_count > 1 )) ||
       ! commit_affects_build "$hash" ||
       ! commit_intersects_net_build_paths "$hash" ||
       ! commit_overlaps_net_diff "$hash"; then
        continue
    fi

    commit_type=$(canonical_commit_type "$subject")
    printf '%s\t%s\t%s\n' "$hash" "$subject" "$commit_type" >> "$records_file"
done < <(git log --reverse --format=$'%H\t%s' "$commit_range")

detect_same_range_reverts

relevant_count=0

while IFS=$'\t' read -r hash subject commit_type; do
    [[ -n "$hash" ]] || continue
    if commit_is_skipped "$hash"; then
        continue
    fi

    relevant_count=$((relevant_count + 1))
    summary_title=$(summarize_commit_title "$hash" "$subject" "$commit_type")
    summary_title=${summary_title//$'\t'/ }
    feature_key=$(feature_group_key "$hash" "$summary_title" "$subject")
    feature_key=${feature_key//$'\t'/ }
    group_label=$(feature_group_label "$feature_key")
    group_label=${group_label//$'\t'/ }
    group_key="${commit_type}:${feature_key}"
    printf '%s\t%s\t%s\t%s\t%s\n' "$group_key" "$summary_title" "$commit_type" "$hash" "$group_label" >> "$entries_file"
    record_contributor_for_commit "$hash"
done < "$records_file"

write_grouped_entries

cat > "$notes_file" <<EOF
## ${release_title} 更新日志
EOF

append_section() {
    local title=$1
    local section_file=$2

    if [[ -s "$section_file" ]]; then
        printf '\n### %s\n\n' "$title" >> "$notes_file"
        cat "$section_file" >> "$notes_file"
    fi
}

append_section "新增功能" "$feat_file"
append_section "修复问题" "$fix_file"
append_section "性能优化" "$perf_file"
append_section "代码重构" "$refactor_file"
append_section "文档更新" "$docs_file"
append_section "代码格式" "$style_file"
append_section "杂项/其他" "$chore_file"
append_section "回滚" "$revert_file"

contributor_count=$(awk 'NF { count++ } END { print count + 0 }' "$contributors_file")
if (( contributor_count >= 2 )); then
    printf '\n## Contributors\n\n' >> "$notes_file"
    first_contributor=true
    while IFS= read -r contributor; do
        [[ -n "$contributor" ]] || continue
        if [[ "$first_contributor" == "true" ]]; then
            first_contributor=false
        else
            printf ', ' >> "$notes_file"
        fi
        printf '%s' "$contributor" >> "$notes_file"
    done < "$contributors_file"
    printf '\n' >> "$notes_file"
fi

cat "$notes_file"
