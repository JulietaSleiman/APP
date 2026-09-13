# SplitWallet REST API Specification (v1 - MVP)

Base URL: `https://api.splitwallet.app/v1`

All requests and responses use `Content-Type: application/json`.
Authentication: `Authorization: Bearer <jwt_token>` (except public auth endpoints).

---

## 1. Authentication (`/auth`)

### 1.1 Sign in with Apple
- **POST** `/auth/apple`
- **Request Body**:
  ```json
  {
    "identityToken": "string (JWT from Apple)",
    "authorizationCode": "string",
    "user": {
      "firstName": "string (optional, first sign-in only)",
      "lastName": "string (optional, first sign-in only)",
      "email": "string (optional, first sign-in only)"
    }
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "token": "string (JWT)",
    "refreshToken": "string",
    "user": {
      "id": "usr_101",
      "name": "Juan Perez",
      "email": "juan@example.com",
      "avatarUrl": null,
      "authMethod": "apple",
      "createdAt": "2026-09-13T10:00:00Z"
    }
  }
  ```

### 1.2 Email & Password
- **POST** `/auth/register` & **POST** `/auth/login`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePassword123"
  }
  ```

---

## 2. Groups (`/groups`)

### 2.1 List user groups
- **GET** `/groups`
- **Response `200 OK`**:
  ```json
  [
    {
      "id": "grp_001",
      "name": "Depto con Male",
      "defaultCurrency": "ARS",
      "memberCount": 2,
      "members": [
        { "id": "usr_101", "name": "Juan", "email": "juan@example.com", "avatarUrl": null },
        { "id": "usr_102", "name": "Male", "email": "male@example.com", "avatarUrl": null }
      ],
      "userNetBalance": {
        "ARS": "1500.00"
      },
      "updatedAt": "2026-09-13T12:00:00Z"
    }
  ]
  ```

### 2.2 Create Group
- **POST** `/groups`
- **Request Body**:
  ```json
  {
    "name": "Viaje a Bariloche",
    "defaultCurrency": "ARS",
    "memberIds": ["usr_102", "usr_103"]
  }
  ```

### 2.3 Group Details
- **GET** `/groups/{groupId}`
- **Response `200 OK`**: Returns group metadata and participant list.

---

## 3. Expenses (`/groups/{groupId}/expenses`)

### 3.1 List Expenses
- **GET** `/groups/{groupId}/expenses?category={cat}&payerId={uid}&page=1&limit=20`
- **Response `200 OK`**:
  ```json
  [
    {
      "id": "exp_501",
      "groupId": "grp_001",
      "description": "Supermercado Coto",
      "amount": "100.00",
      "currency": "ARS",
      "category": "groceries",
      "paidById": "usr_101",
      "date": "2026-09-13T11:30:00Z",
      "splitType": "equal",
      "splits": [
        { "userId": "usr_101", "computedAmount": "33.34", "shareValue": 1.0 },
        { "userId": "usr_102", "computedAmount": "33.33", "shareValue": 1.0 },
        { "userId": "usr_103", "computedAmount": "33.33", "shareValue": 1.0 }
      ],
      "receiptUrl": null,
      "createdAt": "2026-09-13T11:30:00Z",
      "updatedAt": "2026-09-13T11:30:00Z"
    }
  ]
  ```

### 3.2 Create Expense
- **POST** `/groups/{groupId}/expenses`
- **Request Body**:
  ```json
  {
    "description": "Supermercado Coto",
    "amount": "100.00",
    "currency": "ARS",
    "category": "groceries",
    "paidById": "usr_101",
    "date": "2026-09-13T11:30:00Z",
    "splitType": "equal",
    "notes": "Compra semanal de víveres",
    "receiptData": "data:image/jpeg;base64,... (optional)",
    "splits": [
      { "userId": "usr_101", "shareValue": 1.0 },
      { "userId": "usr_102", "shareValue": 1.0 },
      { "userId": "usr_103", "shareValue": 1.0 }
    ]
  }
  ```
- **Rules on Splits**:
  - `equal`: `shareValue` ignored or 1.0. App divides equal parts and server validates.
  - `exact`: `shareValue` is the exact amount. Sum MUST equal `amount`.
  - `percentage`: `shareValue` is % (e.g. 50.0). Sum MUST equal 100.0.
  - `shares`: `shareValue` represents weights (e.g. 2 for user A, 1 for user B).

### 3.3 Upload / Attach Receipt (Roadmap #2)
- **POST** `/groups/{groupId}/expenses/{expenseId}/receipt`
- **Request Header**: `Content-Type: multipart/form-data` or `application/json` (Base64)
- **Request Body (multipart)**: `file: binary image (jpeg, png, heic, max 10MB)`
- **Response `201 Created`**:
  ```json
  {
    "expenseId": "exp_001",
    "receiptUrl": "https://storage.splitwallet.app/receipts/exp_001_thumb.jpg",
    "mimeType": "image/jpeg",
    "fileSizeBytes": 348120,
    "uploadedAt": "2026-09-13T12:00:00Z"
  }
  ```

---

## 4. Settlements & Payment Methods (`/groups/{groupId}/settlements` - Roadmap #5)

### 4.1 Record Settlement (Payment)
- **POST** `/groups/{groupId}/settlements`
- **Request Body**:
  ```json
  {
    "fromUserId": "usr_102",
    "toUserId": "usr_101",
    "amount": "5000.00",
    "currency": "ARS",
    "date": "2026-09-13T12:00:00Z",
    "paymentMethod": "mercado_pago",
    "paymentReference": "MP-8839210",
    "alias": "juan.splitwallet.mp",
    "note": "Transferencia de liquidación de cuentas"
  }
  ```
- **Response `201 Created`**:
  ```json
  {
    "id": "set_001",
    "status": "confirmed",
    "settledAt": "2026-09-13T12:00:05Z"
  }
  ```

---

## 5. Summary & Balances (`/groups/{groupId}/balances`)

### 5.1 Get Calculated Balances & Suggested Payments
- **GET** `/groups/{groupId}/balances`
- **Response `200 OK`**:
  ```json
  {
    "groupId": "grp_001",
    "balancesByCurrency": {
      "ARS": {
        "netBalances": [
          { "userId": "usr_101", "netAmount": "66.66" },
          { "userId": "usr_102", "netAmount": "-33.33" },
          { "userId": "usr_103", "netAmount": "-33.33" }
        ],
        "simplifiedDebts": [
          { "fromUserId": "usr_102", "toUserId": "usr_101", "amount": "33.33" },
          { "fromUserId": "usr_103", "toUserId": "usr_101", "amount": "33.33" }
        ]
      }
    }
  }
  ```

---

## 6. Export Summary & Reports (`/groups/{groupId}/export` - Roadmap #3)

### 6.1 Generate Export Payload / PDF Summary
- **GET** `/groups/{groupId}/export?format=text|pdf`
- **Response `200 OK`**:
  ```json
  {
    "groupId": "grp_001",
    "groupName": "Depto con Male",
    "generatedAt": "2026-09-13T12:30:00Z",
    "totalSpent": "45000.00",
    "currency": "ARS",
    "settlementSummary": [
      { "from": "Male", "to": "Juan (Tú)", "amount": "7500.00" }
    ],
    "shareableText": "📊 *SplitWallet — Resumen Depto con Male*\nTotal gastado: $45.000\n\nLiquidación:\n• Male le debe a Juan: $7.500\n\nGenerado con SplitWallet.",
    "pdfDownloadUrl": "https://storage.splitwallet.app/reports/grp_001_report.pdf"
  }
  ```
