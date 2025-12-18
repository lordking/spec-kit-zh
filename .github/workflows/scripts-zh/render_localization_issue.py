import os
from pathlib import Path
import datetime


def render_localization_issue() -> None:
    """Render localization todo issue body from template and save to file."""
    upstream_commit = os.getenv("UPSTREAM_COMMIT", "")
    current_commit = os.getenv("CURRENT_COMMIT", "")
    merge_status = os.getenv("MERGE_STATUS", "")
    stats = os.getenv("STATS", "")
    changed_files = os.getenv("CHANGED_FILES", "")
    run_url = os.getenv("RUN_URL", "")
    repo_url = os.getenv("REPO_URL", "")

    # 获取当前时间
    now = datetime.datetime.now()
    sync_date = now.strftime("%Y-%m-%d %H:%M:%S")

    # 读取模板文件
    template_path = Path(".github/workflows/scripts/templates/localization-issue-template.md")
    template = template_path.read_text(encoding="utf-8")

    # 准备模板变量
    # 格式化合并状态文本
    if merge_status == "success":
        merge_status_text = "✅ 成功"
    elif merge_status == "conflict":
        merge_status_text = "⚠️ 冲突（需要手动处理）"
    else:
        merge_status_text = merge_status or "未知"

    ctx = {
        "SYNC_DATE": sync_date,
        "MERGE_STATUS": merge_status_text,
        "STATS": stats,
        "CHANGED_FILES": changed_files,
        "RUN_URL": run_url,
        "REPO_URL": repo_url,
        "LOCALIZATION_TASKS": generate_localization_tasks(changed_files)
    }

    # 渲染模板
    issue_body = template.format(**ctx)

    # 保存到文件供action使用
    output_path = Path(".github/workflows/scripts/localization-issue-output.md")
    output_path.write_text(issue_body, encoding="utf-8")


def generate_localization_tasks(changed_files):
    """Generate localization task list from changed files."""
    if not changed_files.strip():
        return "- 无文件变更"

    tasks = []
    for file_path in changed_files.strip().split('\n'):
        file_path = file_path.strip()
        if not file_path:
            continue

        # 根据文件类型判断是否需要汉化
        needs_localization = False
        if any(file_path.endswith(ext) for ext in ['.md', '.txt', '.yml', '.yaml', '.json']):
            needs_localization = True
        elif 'README' in file_path or 'CHANGELOG' in file_path or 'docs/' in file_path:
            needs_localization = True

        if needs_localization:
            tasks.append(f"- [ ] 📄 `{file_path}` - 需要检查并更新中文翻译")
        else:
            tasks.append(f"- [ ] 🔧 `{file_path}` - 代码文件，检查是否影响汉化功能")

    return '\n'.join(tasks) if tasks else "- 无文件变更"


if __name__ == "__main__":
    render_localization_issue()