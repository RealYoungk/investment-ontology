import unittest
from build import classify, build, sentence

def row(code='99999999',industry='70113',text='',name='테스트회사'):
    return dict(corpCode=code,industryCode=industry,name=name,text=text,products=[])

class OverviewTests(unittest.TestCase):
    def test_non_financial_holding(self):
        self.assertEqual(classify(row(industry='64992',text='당사는 비금융지주회사법 적용 회사입니다.'))[0],'holding')
    def test_spac_not_investment_service(self):
        self.assertEqual(classify(row(industry='661',name='테스트기업인수목적'))[0],'spac')
    def test_ship_parts_not_shipyard(self):
        self.assertEqual(classify(row(industry='31114'))[0],'industrial_parts')
    def test_clinical_research_not_contract_research(self):
        text='당사는 항암 치료제를 연구하는 신약개발 기업으로 비임상 및 임상 개발을 자체적으로 수행하고 있습니다.'
        self.assertEqual(classify(row(text=text))[0],'biotech')
    def test_competitor_mention_does_not_change_business(self):
        self.assertEqual(classify(row(industry='21',text='경쟁사 삼성바이오로직스는 CDMO 기업입니다.'))[0],'pharma')
    def test_future_cdmo_does_not_turn_into_actual_cdmo(self):
        text='당사는 플랫폼 기술을 개발하고 있으며 향후 CDMO 사업도 가능합니다.'
        self.assertEqual(sentence(row(text=text)),'')
    def test_source_quote_and_product_evidence(self):
        r=row(text='당사는 고객의 생산 공정에 사용되는 검사장비를 개발하고 제조하여 판매하는 사업을 영위하고 있습니다.')
        r['products']=[{'name':'허구 제품','evidence':'없는 문장'}]
        data,_=build([r]);v=data['companies'][r['corpCode']]
        self.assertEqual(v['summary'],r['text']);self.assertEqual(v['products'],[])
    def test_no_document_is_not_claimed_as_researched(self):
        data,_=build([row(industry='64121')]);v=data['companies']['99999999']
        self.assertFalse(v['hasDocument']);self.assertEqual(v['summary'],'')
    def test_unknown_code_does_not_get_manufacturing(self):
        self.assertEqual(classify(row(industry=''))[0],'unknown')

if __name__=='__main__':unittest.main()
