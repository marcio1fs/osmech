package com.osmech.os.repository;

import com.osmech.os.entity.ServiceOrder;
import com.osmech.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ServiceOrderRepository extends JpaRepository<ServiceOrder, Long> {
    List<ServiceOrder> findByUser(User user);
    List<ServiceOrder> findByUserOrderByCreatedAtDesc(User user);
    List<ServiceOrder> findByStatus(ServiceOrder.OrderStatus status);
}
