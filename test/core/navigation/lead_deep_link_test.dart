import 'package:crm_task_manager/core/navigation/lead_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a tenant lead link', () {
    final link = LeadDeepLink.tryParse(
      'https://fingroupcrm-new.shamcrm.com/leads?lead_id=7270&active_tab=info',
    );

    expect(link, isNotNull);
    expect(link!.section, ShamcrmLinkSection.lead);
    expect(link.leadId, 7270);
    expect(link.host, 'fingroupcrm-new.shamcrm.com');
    expect(link.activeTab, 'info');
    expect(link.organizationId, isNull);
    expect(link.salesFunnelId, isNull);
  });

  test('parses organization and funnel that will be added later', () {
    final link = LeadDeepLink.tryParse(
      'https://retiseg712inraudcom-new.shamcrm.com/leads'
      '?lead_id=2490&organization_id=4&sales_funnel_id=9&active_tab=info',
    );

    expect(link!.leadId, 2490);
    expect(link.organizationId, 4);
    expect(link.salesFunnelId, 9);
    expect(link.host, 'retiseg712inraudcom-new.shamcrm.com');
  });

  test('parses the custom scheme used when the site is not verified yet', () {
    final link = LeadDeepLink.tryParse(
      'shamcrm://leads?lead_id=15&organization_id=2&sales_funnel_id=3',
    );

    expect(link!.leadId, 15);
    expect(link.organizationId, 2);
    expect(link.salesFunnelId, 3);
    expect(link.host, isNull);
  });

  test('any shamcrm.com address opens the app, then picks the section', () {
    final home = LeadDeepLink.tryParse('https://fingroupcrm-new.shamcrm.com/');
    expect(home!.section, ShamcrmLinkSection.app);
    expect(home.entityId, isNull);

    final deal = LeadDeepLink.tryParse(
      'https://fingroupcrm-new.shamcrm.com/deals?deal_id=1',
    );
    expect(deal!.section, ShamcrmLinkSection.deal);
    expect(deal.entityId, 1);

    expect(LeadDeepLink.tryParse('shamcrm://widget?screen=dashboard'), isNull);
    expect(
      LeadDeepLink.tryParse('https://example.com/leads?lead_id=1'),
      isNull,
    );
  });

  test('a link from another company does not match the signed-in tenant', () {
    expect(
      leadLinkMatchesSignedInTenant(
        linkHost: 'other-new.shamcrm.com',
        enteredDomain: 'fingroupcrm-new',
        enteredMainDomain: 'shamcrm.com',
        verifiedDomain: 'fingroupcrm-new-back.shamcrm.com',
      ),
      isFalse,
    );
    expect(
      leadLinkMatchesSignedInTenant(
        linkHost: 'fingroupcrm-new.shamcrm.com',
        enteredDomain: 'fingroupcrm-new',
        enteredMainDomain: 'shamcrm.com',
        verifiedDomain: 'fingroupcrm-new-back.shamcrm.com',
      ),
      isTrue,
    );
  });

  test('classifies a missing lead as no access and a server error as retry', () {
    expect(
      classifyLeadHttpResponse(404, '{"message":"Такого лида не существует"}'),
      LeadLinkAccess.denied,
    );
    expect(
      classifyLeadHttpResponse(200, '{"result":{"id":7}}'),
      LeadLinkAccess.granted,
    );
    expect(
      classifyLeadHttpResponse(200, '{"result":null}'),
      LeadLinkAccess.denied,
    );
    expect(classifyLeadHttpResponse(500, ''), LeadLinkAccess.unavailable);
    expect(classifyLeadHttpResponse(401, ''), LeadLinkAccess.unavailable);
  });
}
