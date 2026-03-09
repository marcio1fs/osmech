package com.osmech.payment.repository;

import com.osmech.payment.entity.MercadoPagoWebhookEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MercadoPagoWebhookEventRepository extends JpaRepository<MercadoPagoWebhookEvent, Long> {

    boolean existsByEventKey(String eventKey);
}
