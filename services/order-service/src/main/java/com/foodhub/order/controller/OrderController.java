package com.foodhub.order.controller;

import com.foodhub.order.dto.OrderRequest;
import com.foodhub.order.model.Order;
import com.foodhub.order.model.OrderItem;
import com.foodhub.order.repository.OrderRepository;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderRepository orders;

    public OrderController(OrderRepository orders) {
        this.orders = orders;
    }

    @PostMapping
    public ResponseEntity<?> place(@Valid @RequestBody OrderRequest req, Authentication auth) {
        for (OrderItem i : req.items()) {
            if (i.getQuantity() < 1 || i.getPrice() < 0) {
                return ResponseEntity.badRequest().build();
            }
        }
        Order order = new Order();
        order.setUserEmail(auth.getName());
        order.setItems(req.items());
        order.setTotal(req.items().stream().mapToDouble(i -> i.getPrice() * i.getQuantity()).sum());
        return ResponseEntity.status(HttpStatus.CREATED).body(orders.save(order));
    }

    @GetMapping
    public List<Order> mine(Authentication auth) {
        return orders.findByUserEmailOrderByCreatedAtDesc(auth.getName());
    }
}
