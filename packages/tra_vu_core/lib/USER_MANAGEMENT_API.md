# User Management API Documentation

This document details the endpoints available in the User Management module (`/v1/users`). All endpoints require a valid `x-tenant-id` header.

## Authentication
Routes marked with **[Auth]** require a Bearer token in the `Authorization` header. The system uses `nestjs-multi-auth` for identity resolution.

---

## Endpoints Summary

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| **`POST`** | `/v1/users` | Create a new user profile manually | Admin/Internal |
| **`GET`** | `/v1/users/me` | Get current authenticated user profile | **[Auth]** |
| **`PATCH`** | `/v1/users/me` | Update current authenticated user profile | **[Auth]** |
| **`GET`** | `/v1/users` | List all users in the current tenant | Admin |
| **`GET`** | `/v1/users/:id` | Get details of a specific user | Admin |
| **`PATCH`** | `/v1/users/:id` | Update a specific user's details | Admin |
| **`DELETE`** | `/v1/users/:id` | Remove a user profile | Admin |

---

## Request & Payload Data Types

### 1. Create User Profile
**`POST /v1/users`**

Used to manually link a `nestjs-multi-auth` identity to a local profile.

**Payload (`CreateUserDto`):**
```json
{
  "firstName": "string",         
  "lastName": "string",          
  "email": "string",             
  "phoneNumber": "string",       
  "authUid": "string"            
}
```

### 2. Get Current User
**`GET /v1/users/me`**

Returns the profile associated with the current Bearer token. If no local profile exists yet, it is automatically resolved/created from the auth identity.

**Response Body:**
```json
{
  "id": "uuid",
  "firstName": "string",
  "lastName": "string",
  "email": "string",
  "phoneNumber": "string",
  "authUid": "string",
  "tenantId": "uuid",
  "isEmailVerified": "boolean",
  "rating": "number",
  "createdAt": "iso-date",
  "updatedAt": "iso-date"
}
```

### 3. Update User Profile
**`PATCH /v1/users/me`** OR **`PATCH /v1/users/:id`**

Used to update profile information. Fields are optional.

**Payload (`UpdateUserDto`):**
```json
{
  "firstName": "string",
  "lastName": "string",
  "phoneNumber": "string"
}
```
> [!NOTE]
> `email` and `authUid` are immutable through these endpoints to ensure identity integrity.

---

## Event Hooks (Internal)

The system automatically listens for the `auth.signup` event emitted by `nestjs-multi-auth`. When a user signs up via EMAIL or PHONE, a local `UserEntity` is automatically initialized with the provided data.
