class CepSigner
  def initialize(proxy)
    @upvs = proxy
  end

  def signatures_info(content)
    request = factory.create_zisti_typ_aformu_podpisu2_req

    request.data_b64 = factory.create_zisti_typ_aformu_podpisu_req_data_b64(content)

    @upvs.ez.call_service(ServiceClassEnum::DITEC_CEP_ZISTI_TYP_A_FORMU_PODPISU_2, request)
  end

  private

  mattr_reader :factory, default: sk.gov.schemas.servicebusserviceprovider.ditec.cepprovider._1.ObjectFactory.new

  java_import sk.gov.schemas.servicebus.service._1.ServiceClassEnum
  java_import sk.gov.schemas.servicebusserviceprovider.ditec.cepprovider._1.Encoding
  java_import sk.gov.schemas.servicebusserviceprovider.ditec.cepprovider._1.ItemChoiceType
  java_import sk.gov.schemas.servicebusserviceprovider.ditec.cepprovider._1.TypVizualizacie
  java_import sk.gov.schemas.servicebusserviceprovider.ditec.cepprovider._1.VerziaFormatuPodpisu
end
