#!/usr/bin/env python3
"""Move flat lib/models/*.dart into domain folders and rewrite imports."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / "lib/models"
LIB = ROOT / "lib"

# filename -> destination folder (relative to lib/models)
MOVES: dict[str, str] = {
    # lead
    "lead_model.dart": "lead",
    "leadById_model.dart": "lead",
    "lead_list_model.dart": "lead",
    "lead_multi_model.dart": "lead",
    "lead_history_model.dart": "lead",
    "lead_deal_model.dart": "lead",
    "lead_sms_model.dart": "lead",
    "lead_filter_channel_model.dart": "lead",
    "lead_navigate_to_chat.dart": "lead",
    "LeadStatusForFilter.dart": "lead",
    "contact_person_model.dart": "lead",
    "notes_model.dart": "lead",
    "reason_for_refusal_model.dart": "lead",
    "source_model.dart": "lead",
    "source_list_model.dart": "lead",
    "advertising_campaign_model.dart": "lead",
    "region_model.dart": "lead",
    "city_model.dart": "lead",
    "manager_model.dart": "lead",
    # deal
    "deal_model.dart": "deal",
    "dealById_model.dart": "deal",
    "deal_history_model.dart": "deal",
    "deal_name_list.dart": "deal",
    "deal_task_model.dart": "deal",
    # task
    "task_model.dart": "task",
    "taskbyId_model.dart": "task",
    "task_Status_Name_model.dart": "task",
    "task_overdue_history_model.dart": "task",
    "history_model_task.dart": "task",
    "project_model.dart": "task",
    "project_task_model.dart": "task",
    "overdue_task_response.dart": "task",
    "user_add_task_model.dart": "task",
    "directory_model.dart": "task",
    "directory_link_model.dart": "task",
    # my_task
    "my-task_model.dart": "my_task",
    "my-taskbyId_model.dart": "my_task",
    "my-task_Status_Name_model.dart": "my_task",
    "history_model_my-task.dart": "my_task",
    # chat
    "chats_model.dart": "chat",
    "chatById_model.dart": "chat",
    "chatGetId_model.dart": "chat",
    "ChatsGetId.dart": "chat",
    "chat_messages_page.dart": "chat",
    "chatTaskProfile_model.dart": "chat",
    "chat_item.dart": "chat",
    "message.dart": "chat",
    "message_reaction_model.dart": "chat",
    "msg_data_in_socket.dart": "chat",
    "template_model.dart": "chat",
    # event / calendar / notices
    "event_model.dart": "event",
    "event_by_Id_model.dart": "event",
    "calendar_model.dart": "event",
    "notice_history_model.dart": "event",
    "notice_sms_sample_model.dart": "event",
    "notice_subject_model.dart": "event",
    # user / org / auth
    "user.dart": "user",
    "user_model.dart": "user",
    "user_byId_model..dart": "user",
    "user_data_response.dart": "user",
    "author_data_response.dart": "user",
    "role_model.dart": "user",
    "permission.dart": "user",
    "organization_model.dart": "user",
    "department.dart": "user",
    "login_model.dart": "auth",
    "domain_check.dart": "auth",
    "email_verification_response.dart": "auth",
    # notifications
    "notifications_model.dart": "notification",
    # workday
    "workday_status_model.dart": "workday",
    "timesheet_models.dart": "workday",
    # sales funnel
    "sales_funnel_model.dart": "sales_funnel",
    # call
    "call_model.dart": "call",
    "call_center_model.dart": "call",
    # fields / config
    "field_configuration.dart": "field",
    "field_position_update.dart": "field",
    "main_field_model.dart": "field",
    # settings / i18n
    "localization_model.dart": "settings",
    "mini_app_settiings.dart": "settings",
    # money-adjacent root leftovers
    "cash_register_list_model.dart": "money",
    "income_categories_data_response.dart": "money",
    "outcome_categories_data_response.dart": "money",
    "income_category_data.dart": "money",
    "outcome_category_data.dart": "money",
    "batch_model.dart": "money",
    "price_type_model.dart": "money",
    # misc / shared
    "api_exception_model.dart": "common",
    "pagination_dto.dart": "common",
    "file_helper.dart": "common",
    "chart_data.dart": "common",
    "integration_model.dart": "common",
    "supplier_list_model.dart": "common",
    "dashboard_goods_movement_history_model.dart": "page_2",
}


def main() -> None:
    # 1) move files
    moved: dict[str, str] = {}  # old package path suffix -> new
    for filename, folder in MOVES.items():
        src = MODELS / filename
        if not src.exists():
            print(f"SKIP missing: {filename}")
            continue
        dest_dir = MODELS / folder
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / filename
        if dest.exists():
            raise SystemExit(f"Destination exists: {dest}")
        src.rename(dest)
        old_pkg = f"package:crm_task_manager/models/{filename}"
        new_pkg = f"package:crm_task_manager/models/{folder}/{filename}"
        moved[old_pkg] = new_pkg
        # also track relative-style endings
        moved[f"models/{filename}"] = f"models/{folder}/{filename}"
        print(f"moved {filename} -> {folder}/")

    if not moved:
        raise SystemExit("Nothing moved")

    # 2) rewrite imports in all dart files under lib/ (and tool if any)
    dart_files = list(LIB.rglob("*.dart"))
    # also update models internal imports
    changed_files = 0
    total_replacements = 0

    # Sort by length desc so longer paths replace first
    pkg_pairs = sorted(
        [(k, v) for k, v in moved.items() if k.startswith("package:")],
        key=lambda x: len(x[0]),
        reverse=True,
    )
    rel_pairs = sorted(
        [(k, v) for k, v in moved.items() if not k.startswith("package:")],
        key=lambda x: len(x[0]),
        reverse=True,
    )

    for path in dart_files:
        text = path.read_text()
        original = text

        for old, new in pkg_pairs:
            if old in text:
                text = text.replace(old, new)

        # relative imports: '../models/foo.dart', '../../models/foo.dart', 'models/foo.dart'
        for old_suffix, new_suffix in rel_pairs:
            # only replace import/export/part uris containing models/<file>
            pattern = re.compile(
                rf"(['\"])([^'\"]*?{re.escape(old_suffix)})(['\"])"
            )

            def _sub(m: re.Match[str], _old=old_suffix, _new=new_suffix) -> str:
                full = m.group(2)
                # avoid double-updating already moved paths like models/lead/foo.dart
                if f"models/" in full and _old in full:
                    # if already has an extra folder segment after models/ before filename, skip
                    # e.g. models/lead/lead_model.dart should not match models/lead_model.dart wait
                    # old_suffix is models/lead_model.dart - wouldn't match models/lead/lead_model.dart
                    updated = full.replace(_old, _new)
                    return f"{m.group(1)}{updated}{m.group(3)}"
                return m.group(0)

            text = pattern.sub(_sub, text)

        if text != original:
            path.write_text(text)
            changed_files += 1
            # rough count
            total_replacements += sum(original.count(o) for o, _ in pkg_pairs)

    print(f"Updated {changed_files} files ({total_replacements} package import hits)")

    # leftover root dart files
    leftover = sorted(p.name for p in MODELS.glob("*.dart"))
    print("Leftover root models:", leftover)


if __name__ == "__main__":
    main()
