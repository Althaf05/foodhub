package com.foodhub.order.dto;

import com.foodhub.order.model.OrderItem;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record OrderRequest(@NotEmpty List<OrderItem> items) {
}
