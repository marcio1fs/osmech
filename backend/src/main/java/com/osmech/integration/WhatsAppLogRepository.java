package com.osmech.integration;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface WhatsAppLogRepository extends JpaRepository<WhatsAppLog, Long> {
	List<WhatsAppLog> findByStatusAndTentativasLessThan(String status, int tentativas);
}
