package com.osmech.auth;

import com.osmech.user.UserDTO;
import com.osmech.user.UserService;
import com.osmech.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin
public class AuthController {
    @Autowired
    private UserService userService;

    @Autowired
    private JwtService jwtService;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody UserDTO userDTO) {
        User user = userService.register(userDTO);
        String token = jwtService.generateToken(user.getUsername());
        return ResponseEntity.ok(new AuthResponse(token));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody UserDTO userDTO) {
        User user = userService.findByUsername(userDTO.getUsername())
                .filter(u -> jwtService.matches(userDTO.getPassword(), u.getPassword()))
                .orElse(null);
        if (user == null) {
            return ResponseEntity.status(401).body("Usuário ou senha inválidos");
        }
        String token = jwtService.generateToken(user.getUsername());
        return ResponseEntity.ok(new AuthResponse(token));
    }

    static class AuthResponse {
        public String token;
        public AuthResponse(String token) { this.token = token; }
        public String getToken() { return token; }
    }
}
