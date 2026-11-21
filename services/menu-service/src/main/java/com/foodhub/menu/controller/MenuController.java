package com.foodhub.menu.controller;

import com.foodhub.menu.model.MenuItem;
import com.foodhub.menu.repository.MenuItemRepository;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/menu")
public class MenuController {

    private final MenuItemRepository items;

    public MenuController(MenuItemRepository items) {
        this.items = items;
    }

    @GetMapping
    public List<MenuItem> list(@RequestParam(required = false) String category) {
        return category == null ? items.findAll() : items.findByCategory(category);
    }

    @GetMapping("/{id}")
    public ResponseEntity<MenuItem> get(@PathVariable String id) {
        return items.findById(id).map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<MenuItem> create(@RequestBody MenuItem item) {
        return ResponseEntity.status(HttpStatus.CREATED).body(items.save(item));
    }
}
