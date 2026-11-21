package com.foodhub.menu.repository;

import com.foodhub.menu.model.MenuItem;
import java.util.List;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface MenuItemRepository extends MongoRepository<MenuItem, String> {
    List<MenuItem> findByCategory(String category);
}
