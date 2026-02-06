-- Insert sample users untuk testing
-- Username: admin / Password: admin123
-- Username: user / Password: user123

INSERT INTO users (username, email, password, fullname, role) VALUES
('admin', 'admin@example.com', '$2y$10$TjmBQxD8K6y9VgYiL6K.ue7VxkXM7vY6j8K9L0M1N2O3P4Q5R6S', 'Administrator', 'admin'),
('user', 'user@example.com', '$2y$10$BXo9xX..6aFqYx8N7qXqL.eL7K4V2r1M9n8O7p6Q5r4S3t2U', 'Regular User', 'user');

-- Verify
SELECT id, username, email, fullname, role FROM users;
