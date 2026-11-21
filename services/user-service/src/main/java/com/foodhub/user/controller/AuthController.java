package com.foodhub.user.controller;

import com.foodhub.user.dto.LoginRequest;
import com.foodhub.user.dto.RegisterRequest;
import com.foodhub.user.model.User;
import com.foodhub.user.repository.UserRepository;
import com.foodhub.user.security.JwtService;
import jakarta.validation.Valid;
import java.util.Map;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final JwtService jwt;

    public AuthController(UserRepository users, PasswordEncoder encoder, JwtService jwt) {
        this.users = users;
        this.encoder = encoder;
        this.jwt = jwt;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest req) {
        String email = req.email().toLowerCase();
        if (users.findByEmail(email).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "Email already registered"));
        }
        User saved = users.save(new User(email, encoder.encode(req.password()), req.name()));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("id", saved.getId(), "email", saved.getEmail(), "name", saved.getName()));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest req) {
        Optional<User> found = users.findByEmail(req.email().toLowerCase());
        if (found.isEmpty() || !encoder.matches(req.password(), found.get().getPasswordHash())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid email or password"));
        }
        User u = found.get();
        String token = jwt.createToken(u.getId(), u.getEmail(), u.getRole());
        return ResponseEntity.ok(Map.of("token", token, "type", "Bearer"));
    }

    @GetMapping("/me")
    public ResponseEntity<?> me(Authentication auth) {
        return ResponseEntity.ok(Map.of("email", auth.getName(),
                "roles", auth.getAuthorities().toString()));
    }
}
