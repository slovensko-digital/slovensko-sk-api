package digital.slovensko.upvs.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import sk.gov.schemas.servicebus.service._1.ServiceClassEnum;
import sk.gov.schemas.servicebus.service._1_0.IServiceBus;
import sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.*;

import static sk.gov.schemas.servicebus.service._1.ServiceClassEnum.*;

/*
 * TODO support through all service classes
 *
 * service classes have been generated only for eForm via
 * https://vyvoj.upvs.globaltel.sk/ServiceBus/SbWsdlGeneratorToken.aspx
 *
 * to generate java classes for all service classes use
 * https://vyvoj.upvs.globaltel.sk/ServiceBus/ServiceBusToken.svc
 *
 * note that the wsdl needs some naming fixes
 */

/**
 * EZ - Externá zbernica
 * <p>
 * USR - Univerzálne sériové rozhranie
 */
@Component
public final class EzClient {
    private static final Logger log = LoggerFactory.getLogger(EzClient.class);

    @Autowired
    private IServiceBus service;

    /**
     * @see https://vyvoj.upvs.globaltel.sk/ServiceBus/SbWsdlGeneratorToken.aspx
     */

    public Object call(final ServiceClassEnum method, final Object request) {
        return this.service.callService(method, request);
    }

    public FindFormTemplatesRes findFormTemplates() {
        FindFormTemplatesReq request = new FindFormTemplatesReq();
        return (FindFormTemplatesRes) this.call(EFORM_FINDFORMTEMPLATES_SOAP_V_1_0, request);
    }
}