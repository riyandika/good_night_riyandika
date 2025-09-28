# Good Night API

A comprehensive sleep tracking API built with Ruby on Rails that helps users monitor their sleep patterns and connect with friends through social sleep features.

## Features

### Sleep Tracking
- **Clock In/Out**: Track sleep sessions with automatic duration calculation
- **Sleep History**: View paginated sleep records with recent-first ordering
- **Sleep Analytics**: Duration tracking with precise timestamps

### Social Features
- **Follow System**: Follow and unfollow other users
- **Friends' Sleep Leaderboard**: View friends' sleep records from the past week, sorted by duration
- **Social Sleep Insights**: Compare sleep patterns with your network

### Data & Analytics
- **Pagination**: All endpoints support efficient pagination
- **Time-based Filtering**: Past week sleep data for social features
- **Performance Optimized**: Database indexes for fast queries

### API Documentation
- **Interactive Swagger UI**: Complete API documentation with try-it-out functionality
- **OpenAPI 3.0 Compliant**: Professional API specifications
- **Auto-generated**: Documentation stays in sync with actual API

## Tech Stack

- **Framework**: Ruby on Rails 8.0.2
- **Database**: MySQL 8.0
- **Authentication**: Parameter-based user identification
- **Serialization**: Active Model Serializers
- **Pagination**: Kaminari gem
- **Documentation**: Rswag (Swagger/OpenAPI)
- **Testing**: RSpec with comprehensive test coverage
- **Code Quality**: RuboCop with Rails Omakase styling

## API Endpoints

### Users
- `GET /api/v1/users` - List all users (paginated)
- `GET /api/v1/users/:id` - Get user details

### Sleep Records
- `POST /api/v1/users/:user_id/sleep_records` - Clock in/out for sleep tracking
- `GET /api/v1/users/:user_id/sleep_records` - Get user's sleep history (paginated)
- `GET /api/v1/users/:user_id/sleep_records/friends_sleep_records` - Get friends' sleep records from past week (paginated, sorted by duration)

### Social Features
- `POST /api/v1/users/:user_id/follows` - Follow another user
- `GET /api/v1/users/:user_id/follows` - List user's followings (paginated)
- `DELETE /api/v1/users/:user_id/follows/:target_user_id` - Unfollow a user

## Installation & Setup

### Prerequisites
- Ruby 3.2.5 or higher
- MySQL 8.0 or higher

### 1. Clone the Repository
```bash
git clone https://github.com/riyandika/good_night_riyandika.git
cd good_night_riyandika
```

### 2. Install Dependencies
```bash
bundle install
```

### 3. Environment Setup
Copy the environment template and configure your database:
```bash
cp .env.template .env
# Edit .env with your database credentials
```

### 4. Database Setup
```bash
rails db:create
rails db:migrate
rails db:seed  # Optional: seed with sample data
```

### 5. Start the Server
```bash
rails server
```

The API will be available at `http://localhost:3000`

## API Documentation

### Interactive Documentation
Visit the Swagger UI for complete API documentation:
```
http://localhost:3000/api-docs
```

### Features:
- **Try it out**: Test all endpoints directly from the browser
- **Request/Response schemas**: Complete data structure documentation
- **Error handling**: Detailed error response documentation
- **Examples**: Real request/response examples for all endpoints

## Testing

### Run All Tests
```bash
bundle exec rspec
```

### Run Specific Test Suites
```bash
# API request tests
bundle exec rspec spec/requests/

# Model tests
bundle exec rspec spec/models/

# Swagger documentation tests
bundle exec rspec spec/requests/api/v1/swagger/
```

### Test Coverage
- **Request tests**: Complete API endpoint coverage
- **Model tests**: Business logic and validation testing
- **Swagger tests**: Documentation accuracy verification

```

## Database Schema

### Key Tables
- **users**: User profiles and authentication
- **sleep_records**: Sleep tracking data with timestamps and duration
- **follows**: Social follow relationships

### Performance Features
- **Optimized indexes** for fast queries
- **Composite indexes** for complex social queries
- **Pagination support** for large datasets

## Development

### Code Quality
```bash
# Run RuboCop for code style
rubocop

# Auto-fix style issues
rubocop -a
```

### Database Management
```bash
# Create migration
rails generate migration MigrationName

# Run migrations
rails db:migrate

# Rollback migration
rails db:rollback
```

### Generate Documentation
```bash
# Update API documentation
rails rswag
```

## Performance Features

### Database Optimizations
- **Indexed queries** for sub-millisecond response times
- **Efficient pagination** handling thousands of records
- **Optimized joins** for social features

### API Performance
- **Paginated responses** prevent memory overload
- **Selective serialization** for optimal payload sizes
- **Database connection pooling** for concurrent requests

## Security Features

- **Parameter validation** on all endpoints
- **SQL injection prevention** through parameterized queries
- **Input sanitization** for all user data
- **Error handling** without information leakage

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests (`bundle exec rspec`)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Support

For support and questions:
- **Issues**: Use GitHub Issues for bug reports and feature requests
- **Documentation**: Check `/api-docs` for complete API documentation

## Project Structure

```
app/
├── controllers/api/v1/     # API controllers
├── models/                 # ActiveRecord models
├── serializers/           # API response serialization
└── concerns/              # Shared controller logic

spec/
├── requests/api/v1/       # API integration tests
├── requests/api/v1/swagger/ # API documentation tests
├── models/                # Model unit tests
└── factories/             # Test data factories

swagger/v1/                # Generated API documentation
```

---

Built with ❤️ for better sleep tracking and social wellness.