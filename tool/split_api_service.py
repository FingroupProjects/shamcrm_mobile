#!/usr/bin/env python3
"""Split api_service.dart into domain folders via part/part of + extensions."""

from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "lib/api/service/api_service.dart"
BACKUP = ROOT / "lib/api/service/api_service.dart.backup_before_split"
OUT_DIR = ROOT / "lib/api/service"
PART_OF = "part of '../api_service.dart';\n\n"

DOMAIN_FILES = {
    "core_http": "core/api_http.dart",
    "core_session": "core/api_session.dart",
    "core_init": "core/api_init.dart",
    "core_misc": "core/api_misc.dart",
    "auth": "auth/api_auth.dart",
    "workday": "workday/api_workday.dart",
    "fcm": "fcm/api_fcm_voip.dart",
    "organization": "organization/api_organization.dart",
    "leads": "leads/api_leads.dart",
    "deals": "deals/api_deals.dart",
    "tasks": "tasks/api_tasks.dart",
    "my_tasks": "my_tasks/api_my_tasks.dart",
    "chats": "chats/api_chats.dart",
    "analytics": "analytics/api_analytics.dart",
    "notifications": "notifications/api_notifications.dart",
    "events": "events/api_events.dart",
    "warehouse_catalog": "warehouse/api_catalog.dart",
    "warehouse_documents": "warehouse/api_documents.dart",
    "warehouse_orders": "warehouse/api_orders.dart",
    "warehouse_dashboards": "warehouse/api_dashboards.dart",
    "warehouse_call_center": "warehouse/api_call_center.dart",
    "cash": "cash/api_cash.dart",
    "sales_plan": "sales_plan/api_sales_plan.dart",
    "localization": "localization/api_localization.dart",
}

EXT_NAMES = {
    "core_http": "ApiHttp",
    "core_session": "ApiSession",
    "core_init": "ApiInit",
    "core_misc": "ApiMisc",
    "auth": "ApiAuth",
    "workday": "ApiWorkday",
    "fcm": "ApiFcmVoip",
    "organization": "ApiOrganization",
    "leads": "ApiLeads",
    "deals": "ApiDeals",
    "tasks": "ApiTasks",
    "my_tasks": "ApiMyTasks",
    "chats": "ApiChats",
    "analytics": "ApiAnalytics",
    "notifications": "ApiNotifications",
    "events": "ApiEvents",
    "warehouse_catalog": "ApiWarehouseCatalog",
    "warehouse_documents": "ApiWarehouseDocuments",
    "warehouse_orders": "ApiWarehouseOrders",
    "warehouse_dashboards": "ApiWarehouseDashboards",
    "warehouse_call_center": "ApiWarehouseCallCenter",
    "cash": "ApiCash",
    "sales_plan": "ApiSalesPlan",
    "localization": "ApiLocalization",
}

STATIC_NAMES = [
    "_defaultRequestTimeout",
    "workdayReadPermission",
    "_tojsokhtmontjSubdomains",
    "_stomatradeSubdomains",
    "navigatorKey",
    "scaffoldMessengerKey",
    "_lastWorkdayWarningAt",
    "_isWorkdayRedirectInProgress",
    "_isForceLogoutInProgress",
    "_noSessionCheckEndpoints",
    "_analyticsFilters",
    "_analyticsResponseCache",
    "_pendingFcmKey",
    "_pendingVoipKey",
    "_voipSyncStatusKey",
    "_voipSyncAtKey",
    "_voipSyncHttpCodeKey",
    "_voipSyncErrorKey",
    "_excludedEndpoints",
    "setAnalyticsFilters",
    "clearAnalyticsFilters",
    "clearAnalyticsResponseCache",
]

FLAT_ORPHANS = [
    "api_service_base.dart",
    "api_http.dart",
    "api_session.dart",
    "api_init.dart",
    "api_misc.dart",
    "api_auth.dart",
    "api_workday.dart",
    "api_fcm_voip.dart",
    "api_organization.dart",
    "api_leads.dart",
    "api_deals.dart",
    "api_tasks.dart",
    "api_my_tasks.dart",
    "api_chats.dart",
    "api_analytics.dart",
    "api_notifications.dart",
    "api_events.dart",
    "api_warehouse_catalog.dart",
    "api_warehouse_documents.dart",
    "api_warehouse_orders.dart",
    "api_warehouse_dashboards.dart",
    "api_warehouse_call_center.dart",
    "api_cash.dart",
    "api_sales_plan.dart",
    "api_localization.dart",
]


def brace_delta(s: str) -> int:
    i = 0
    delta = 0
    n = len(s)
    while i < n:
        c = s[i]
        if c == "/" and i + 1 < n and s[i + 1] == "/":
            break
        if c == "/" and i + 1 < n and s[i + 1] == "*":
            i += 2
            while i + 1 < n and not (s[i] == "*" and s[i + 1] == "/"):
                i += 1
            i += 2
            continue
        if c in ('"', "'"):
            quote = c
            i += 1
            while i < n:
                if s[i] == "\\":
                    i += 2
                    continue
                if s[i] == quote:
                    i += 1
                    break
                i += 1
            continue
        if c == "{":
            delta += 1
        elif c == "}":
            delta -= 1
        i += 1
    return delta


def is_field_line(line: str) -> bool:
    s = line.strip()
    if not s or s.startswith("//") or s.startswith("@") or s.startswith("///"):
        return False
    code = s.split("//")[0].rstrip()
    if "(" in code:
        return False
    if re.match(r"^(static\s+)?(const|final|late|var)\b", code):
        return True
    if re.match(r"^static\s+\w", code) and not code.startswith("static void"):
        if re.search(r"\b\w+\s*[;=]", code):
            return True
    if re.match(
        r"^(bool|int|double|String|DateTime|Duration|Map|List|Set|GlobalKey|dynamic)\b",
        code,
    ) and re.search(r"\b\w+\s*[;=]", code):
        return True
    if re.match(r"^[A-Z]\w*(\??|<.*>)?\s+_?\w+\s*[;=]", code):
        return True
    return False


def is_method_start(line: str, next_line: str | None) -> bool:
    s = line.strip()
    if not s or s.startswith("//") or s.startswith("///") or s.startswith("@"):
        return False
    if is_field_line(line):
        return False
    code = s.split("//")[0]
    if "(" in code:
        if re.match(
            r"^(static\s+)?(Future|void|bool|String|int|double|dynamic|Map|List|Widget|Uri|http\.|DomainCheck|[A-Z_])",
            code,
        ) or re.match(r"^ApiService\s*\(", code):
            return True
        if re.search(r"\bget\s+\w+\s*[({]", code):
            return True
        if re.match(r"^(static\s+)?[A-Za-z_].*\(.*", code) and not code.endswith(";"):
            return True
    if re.match(r"^(static\s+)?(Future<.*>|List<.*>|Map<.*>|[A-Z]\w*<.*>)\s*$", code):
        if next_line and "(" in next_line:
            return True
    return False


def classify(name: str, start_line: int) -> str:
    n = name
    nl = name.lower()

    if n in {
        "_getRequest", "_postRequest", "_putRequest", "_patchRequest",
        "_deleteRequest", "_deleteRequestWithBody", "_multipartPostRequest",
        "_postRequestDomain", "_handleResponse", "_analyticsRequest",
        "_getAnalyticsChartJsonMap", "_appendAnalyticsFiltersToPath",
        "_appendQueryParams", "_extractErrorMessageFromResponse",
        "_extractPrimaryMessageFromResponse", "_getOrderStatusChangeErrorMessage",
        "_getErrorMessage", "_boolToMultipartFlag", "_goodsRequestHasFiles",
        "_buildGoodsRequestBody",
    }:
        return "core_http"

    if n in {
        "getToken", "_saveToken", "_removeToken", "logout", "logoutAccount",
        "_clearWidgetPermissions", "_removePermissions", "_isSessionValid",
        "_forceLogoutAndRedirect", "_redirectToLogin", "reset",
        "getUserByEmail", "saveEmailVerificationData", "getVerifiedLogin",
        "getVerifiedDomain", "initializeWithEmailFlow", "clearEmailVerificationData",
    }:
        return "core_session"

    if n in {
        "_initializeIfDomainExists", "initialize", "_setFallbackDomain",
        "initializeWithDomain", "getDynamicBaseUrl", "getSocketBaseUrl",
        "ensureInitialized", "_getQrDomain", "initializeFromQrData",
        "saveQrData", "getQrData", "checkDomain", "saveDomainChecked",
        "isDomainChecked", "saveDomain", "getEnteredDomain", "getStaticBaseUrl",
        "getFileUrl", "getCurrentTenantSubdomain", "isTojsokhtmontjTenant",
        "isStomatradeTenant",
    }:
        return "core_init"

    if any(x in nl for x in ("workday", "timesheet", "canreadtimesheet")):
        return "workday"

    if any(x in nl for x in (
        "fcm", "voip", "devicetoken", "pendingtoken",
        "sendincomingcallpush", "sendsipready",
    )):
        return "fcm"

    if n in {
        "login", "forgotPin", "savePermissions", "getPermissions",
        "hasPermission", "fetchPermissionsByRoleId", "checkUserAccess",
    }:
        return "auth"

    if any(x in nl for x in (
        "organization", "salesfunnel", "selectedorganization",
        "ensureselectedsalesfunnel",
    )):
        return "organization"

    if "mytask" in nl or n.startswith("_handleMyTask"):
        return "my_tasks"

    if any(x in n for x in ("Chat", "Message", "Template")) or any(
        x in nl for x in (
            "chat", "whatsapp", "telegram", "unreadcount",
            "sendfile", "sendtext", "sendvoice",
        )
    ):
        if "Lead" in n and "Chat" in n:
            return "leads"
        if "Task" in n and ("Chat" in n or "Profile" in n):
            return "tasks"
        if "Notification" in n:
            return "notifications"
        return "chats"

    if "notification" in nl:
        return "notifications"

    if "salesplan" in nl or "SalesPlan" in n:
        return "sales_plan"

    if any(x in nl for x in ("localization", "changelanguage")):
        return "localization"

    if any(x in n for x in (
        "CashRegister", "CashDesk", "MoneyIncome", "MoneyOutcome",
        "Debtor", "Creditor",
    )) or any(x in nl for x in (
        "cashregister", "cashdesk", "moneyincome", "moneyoutcome",
        "debtor", "creditor", "cashbalance", "reconciliationact",
        "salaryreport",
    )):
        return "cash"

    if re.match(r"^(get|create|update|delete|edit).*(Expense|Income)", n) and \
            "Article" not in n and "Structure" not in n and "Dashboard" not in n:
        return "cash"
    if "IncomeCategory" in n or "OutcomeCategory" in n or "ExpenseCategory" in n:
        return "cash"

    if any(x in n for x in (
        "CallCenter", "CallLog", "CallStat", "Operator",
        "MonthlyCall", "CallSummary", "CallAnalytics",
    )) or n.startswith("getCall") or n.startswith("createCall"):
        if "Voip" not in n and "Sip" not in n:
            return "warehouse_call_center"

    if any(x in nl for x in (
        "chart", "conversion", "dealstats", "processspeed", "taskcompletion",
        "usertask", "analytics", "applyanalytics", "telephony", "onlinestore",
        "advertisingroi", "targetedads", "messagestats", "repliesmessage",
        "completedtask", "connectedaccount", "dashboardstatistic",
        "dealsbymanager", "sourceoflead", "topsellingproduct",
    )) and start_line < 12556:
        return "analytics"

    if any(x in n for x in ("Event", "Tutorial", "MiniApp")) or n in {
        "getSettings", "updateProfile", "getUserById", "getProfile",
        "getSubjects", "getSmsSamples", "createNotice", "updateNotice",
        "deleteNotice", "getNotices",
    }:
        if not ("History" in n and ("Lead" in n or "Deal" in n)):
            return "events"

    if any(x in n for x in (
        "Lead", "Region", "City", "Source", "Manager", "ContactPerson",
        "Advertising", "Notes", "Note", "Channel", "ReasonForRefusal",
    )) or any(x in nl for x in ("lead", "contactperson", "reasonforrefusal")):
        if "Deal" in n and "Lead" not in n:
            pass
        elif "Task" in n and "Lead" not in n:
            pass
        elif "Order" in n and "Lead" in n:
            return "warehouse_orders"
        elif any(x in n for x in ("Chart", "Conversion", "Stats")):
            return "analytics"
        else:
            return "leads"

    if "Deal" in n or ("deal" in nl and "ideal" not in nl):
        if any(x in n for x in ("Chart", "Stats", "stats")):
            return "analytics"
        if "Lead" in n:
            return "leads"
        return "deals"

    if any(x in n for x in ("Task", "Project", "Directory")):
        if "MyTask" in n:
            return "my_tasks"
        if any(x in n for x in ("Chart", "Completion", "UserTask")):
            return "analytics"
        return "tasks"

    if any(x in n for x in (
        "Order", "DeliveryAddress", "Branch", "Label", "Variant",
        "PriceType", "LeadOrder",
    )):
        if "OrderStatusWarehouse" in n or "OrderDashboard" in n:
            return "warehouse_dashboards"
        if n == "getOrderHistory" and start_line < 12556:
            return "deals"
        return "warehouse_orders"

    if any(x in n for x in (
        "Incoming", "ClientSale", "ClientReturn", "SupplierReturn", "WriteOff",
        "Movement", "Manufacture", "Document", "Opening", "MeasureUnit",
        "Units", "Storage", "WareHouse", "Supplier", "ExpenseArticle",
        "ArticleGood", "getAllExpenseArticles",
    )) or any(x in nl for x in (
        "incoming", "clientsale", "clientreturn", "supplierreturn", "writeoff",
        "manufacture", "opening", "measureunit",
    )):
        if "Dashboard" in n or "GoodMovementHistory" in n:
            return "warehouse_dashboards"
        return "warehouse_documents"

    if any(x in n for x in (
        "Goods", "Good", "Category", "Barcode", "Character",
        "Attribute", "SubCategory",
    )):
        if "Dashboard" in n:
            return "warehouse_dashboards"
        return "warehouse_catalog"

    if any(x in n for x in (
        "Dashboard", "SalesDynamics", "NetProfit", "Profitability",
        "TopSelling", "Illiquid", "ExpenseStructure", "FieldConfiguration",
        "CustomField", "MainField",
    )):
        if any(x in n for x in ("FieldConfiguration", "CustomField", "MainField")):
            return "core_misc"
        if start_line < 12556:
            return "analytics"
        return "warehouse_dashboards"

    if start_line < 740:
        return "core_init"
    if 740 <= start_line < 983:
        return "workday"
    if 983 <= start_line < 2029:
        return "core_http"
    if 2029 <= start_line < 2436:
        return "fcm"
    if 2436 <= start_line < 2671:
        return "core_init"
    if 2671 <= start_line < 2940:
        return "auth"
    if 2940 <= start_line < 5173:
        return "leads"
    if 5173 <= start_line < 6414:
        return "deals"
    if 6414 <= start_line < 8186:
        return "tasks"
    if 8186 <= start_line < 9041:
        return "analytics"
    if 9041 <= start_line < 10747:
        return "chats"
    if 10747 <= start_line < 11095:
        return "organization"
    if 11095 <= start_line < 11310:
        return "notifications"
    if 11310 <= start_line < 12076:
        return "my_tasks"
    if 12076 <= start_line < 12556:
        return "events"
    if 12556 <= start_line < 16968:
        return "warehouse_catalog"
    if 16968 <= start_line < 18400:
        return "cash"
    if 18400 <= start_line < 21742:
        return "warehouse_dashboards"
    if 21742 <= start_line < 22210:
        return "core_misc"
    if 22210 <= start_line < 22989:
        return "warehouse_documents"
    if 22989 <= start_line < 23200:
        return "localization"
    return "sales_plan"


def qualify_statics(body: str) -> str:
    for name in sorted(STATIC_NAMES, key=len, reverse=True):
        pattern = re.compile(rf"(?<!ApiService\.)(?<![.\w]){re.escape(name)}\b")
        body = pattern.sub(f"ApiService.{name}", body)
    return body


def find_class_bounds(lines: list[str]):
    class_start = next(i for i, l in enumerate(lines) if l.startswith("class ApiService"))
    depth = 0
    class_end = None
    for i in range(class_start, len(lines)):
        depth += brace_delta(lines[i])
        if i > class_start and depth == 0:
            class_end = i
            break
    return class_start, class_end


def find_members(lines, class_start, class_end):
    fields = []
    methods = []
    depth = 0
    i = class_start
    while i <= class_end:
        line = lines[i]
        prev = depth
        if prev == 1:
            j = i + 1
            while j <= class_end and not lines[j].strip():
                j += 1
            nxt = lines[j] if j <= class_end else None

            if is_field_line(line):
                start = i
                k = i
                d_local = 0
                while k <= class_end:
                    d_local += brace_delta(lines[k])
                    if ";" in lines[k] and d_local == 0:
                        break
                    k += 1
                name_m = re.search(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*[;=]", line)
                name = name_m.group(1) if name_m else f"field_{i+1}"
                fields.append((name, start, k))
                for t in range(i, k + 1):
                    depth += brace_delta(lines[t])
                i = k + 1
                continue

            if is_method_start(line, nxt):
                start = i
                while start > class_start + 1:
                    p = lines[start - 1].strip()
                    if p.startswith("@") or p.startswith("///"):
                        start -= 1
                        continue
                    break
                sig = "\n".join(lines[i : i + 8])
                name_m = re.search(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*\(", sig)
                if not name_m:
                    name_m = re.search(r"\bget\s+([A-Za-z_][A-Za-z0-9_]*)", sig)
                name = name_m.group(1) if name_m else f"method_{i+1}"
                k = i
                d_local = 0
                seen = False
                while k <= class_end:
                    d_local += brace_delta(lines[k])
                    if d_local > 0:
                        seen = True
                    if seen and d_local == 0:
                        break
                    if (not seen) and "=>" in lines[k] and lines[k].rstrip().endswith(";"):
                        break
                    k += 1
                methods.append((name, start, k))
                for t in range(i, k + 1):
                    depth += brace_delta(lines[t])
                i = k + 1
                continue

        depth += brace_delta(line)
        i += 1
    return fields, methods


def ensure_monolith_source() -> None:
    """Use current monolith if present; otherwise restore from backup."""
    lines = len(SRC.read_text().splitlines()) if SRC.exists() else 0
    if lines > 5000:
        # Current file is the monolith — refresh backup from it.
        shutil.copy2(SRC, BACKUP)
        print(f"Using current monolith ({lines} lines); backup refreshed")
        return
    if BACKUP.exists() and len(BACKUP.read_text().splitlines()) > 5000:
        shutil.copy2(BACKUP, SRC)
        print(f"Restored monolith from backup ({len(SRC.read_text().splitlines())} lines)")
        return
    raise SystemExit(
        f"No monolith source found. api_service.dart has {lines} lines, "
        f"backup missing or too small."
    )


def cleanup_previous_outputs() -> None:
    for name in FLAT_ORPHANS:
        p = OUT_DIR / name
        if p.exists():
            p.unlink()
            print("removed orphan", name)
    for rel in list(DOMAIN_FILES.values()) + ["core/api_service_base.dart"]:
        p = OUT_DIR / rel
        if p.exists():
            p.unlink()
    # remove empty domain dirs later after write


def main():
    ensure_monolith_source()
    cleanup_previous_outputs()

    lines = SRC.read_text().splitlines()
    class_start, class_end = find_class_bounds(lines)
    fields, methods = find_members(lines, class_start, class_end)
    print(f"Class L{class_start+1}-{class_end+1} fields={len(fields)} methods={len(methods)}")

    field_names = {n for n, _, _ in fields}
    if "_defaultRequestTimeout" not in field_names:
        for i, l in enumerate(lines[class_start : class_end + 1], start=class_start):
            if "_defaultRequestTimeout" in l and "Duration" in l:
                fields.insert(0, ("_defaultRequestTimeout", i, i))
                break

    header = lines[:class_start]
    trailing = lines[class_end + 1 :]

    ctor = None
    static_methods = []
    instance_methods = []
    for name, s, e in methods:
        head = "\n".join(lines[s : min(s + 3, e + 1)])
        if name == "ApiService":
            ctor = (name, s, e)
        elif re.search(r"(^|\n)\s*static\s+", head):
            static_methods.append((name, s, e))
        else:
            instance_methods.append((name, s, e))

    domain_methods: dict[str, list] = {}
    for name, s, e in instance_methods:
        d = classify(name, s + 1)
        domain_methods.setdefault(d, []).append((name, s, e))

    for d, items in sorted(domain_methods.items(), key=lambda x: -len(x[1])):
        print(f"  {d}: {len(items)}")

    for rel in list(DOMAIN_FILES.values()) + ["core/api_service_base.dart"]:
        (OUT_DIR / rel).parent.mkdir(parents=True, exist_ok=True)

    instance_fields = []
    static_fields = []
    for name, s, e in fields:
        chunk = "\n".join(lines[s : e + 1])
        if chunk.lstrip().startswith("static "):
            static_fields.append(chunk)
        else:
            instance_fields.append(chunk)

    base = PART_OF + "abstract class ApiServiceBase {\n"
    base += "\n\n".join(instance_fields) + "\n}\n"
    (OUT_DIR / "core/api_service_base.dart").write_text(base)
    print(f"Wrote core/api_service_base.dart ({len(base.splitlines())} lines)")

    order = [
        "core_http", "core_session", "core_init", "core_misc",
        "auth", "workday", "fcm", "organization", "leads", "deals", "tasks",
        "my_tasks", "chats", "analytics", "notifications", "events",
        "warehouse_catalog", "warehouse_documents", "warehouse_orders",
        "warehouse_dashboards", "warehouse_call_center", "cash",
        "sales_plan", "localization",
    ]
    used = []
    for d in order:
        items = domain_methods.get(d) or []
        if not items:
            continue
        used.append(d)
        bodies = [qualify_statics("\n".join(lines[s : e + 1])) for _, s, e in items]
        # session needs _clearWidgetPermissions if classified into session
        content = (
            PART_OF
            + f"extension {EXT_NAMES[d]}X on ApiService {{\n"
            + "\n\n".join(bodies)
            + "\n}\n"
        )
        path = OUT_DIR / DOMAIN_FILES[d]
        path.write_text(content)
        print(f"Wrote {DOMAIN_FILES[d]} ({len(items)} methods, {len(content.splitlines())} lines)")

    for d, items in domain_methods.items():
        if d in used or not items:
            continue
        print(f"WARNING unlisted domain {d} with {len(items)} methods -> core/api_extra.dart")
        used.append(d)
        DOMAIN_FILES[d] = "core/api_extra.dart"
        EXT_NAMES[d] = "ApiExtra"
        bodies = [qualify_statics("\n".join(lines[s : e + 1])) for _, s, e in items]
        content = (
            PART_OF
            + f"extension {EXT_NAMES[d]}X on ApiService {{\n"
            + "\n\n".join(bodies)
            + "\n}\n"
        )
        path = OUT_DIR / DOMAIN_FILES[d]
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    parts = "part 'core/api_service_base.dart';\n" + "\n".join(
        f"part '{DOMAIN_FILES[d]}';" for d in used
    )
    ctor_block = (
        qualify_statics("\n".join(lines[ctor[1] : ctor[2] + 1]))
        if ctor
        else "  ApiService();"
    )
    static_method_blocks = ["\n".join(lines[s : e + 1]) for _, s, e in static_methods]

    new_main = "\n".join(header).rstrip() + "\n\n"
    new_main += parts + "\n\n"
    new_main += "class ApiService extends ApiServiceBase {\n"
    new_main += "\n\n".join(static_fields + [ctor_block] + static_method_blocks) + "\n"
    new_main += "}\n"
    trail = "\n".join(trailing).strip("\n")
    if trail:
        new_main += "\n" + trail + "\n"
    SRC.write_text(new_main)
    print(f"Main -> {len(new_main.splitlines())} lines")

    # Ensure _clearWidgetPermissions lives in session if logout needs it
    session = OUT_DIR / "core/api_session.dart"
    if session.exists() and "_clearWidgetPermissions" not in session.read_text():
        # pull from backup monolith if present in original classify as core_session - already should be
        pass


if __name__ == "__main__":
    main()
