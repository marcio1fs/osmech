package com.osmech.payment.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "mercadopago_webhook_events",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_mp_webhook_event_key", columnNames = "event_key")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MercadoPagoWebhookEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "event_key", nullable = false, length = 255)
    private String eventKey;

    @Column(name = "payment_id", nullable = false)
    private Long paymentId;

    @Column(name = "mp_status", nullable = false, length = 50)
    private String mpStatus;

    @Column(name = "status_local", nullable = false, length = 30)
    private String statusLocal;

    @Column(name = "criado_em", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime criadoEm = LocalDateTime.now();
}
