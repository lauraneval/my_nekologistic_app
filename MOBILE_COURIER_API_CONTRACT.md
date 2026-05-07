# Courier Mobile API Contract

This document describes the backend contract used by the Flutter courier app for bag-based delivery.

## Authentication

- Send the Supabase access token in `Authorization: Bearer <token>`.
- The API accepts roles `kurir`, `admin_gudang`, and `superadmin` for read operations.
- Delivery mutations should only be used by `kurir` on their assigned bag.

## 1. Task List

`GET /api/courier/tasks?status=OUT_FOR_DELIVERY`

Returns bags assigned to the logged-in courier.

Response shape:

```json
{
  "data": [
    {
      "id": "uuid",
      "bag_code": "BAG-2026-1A2B",
      "destination_city": "Semarang",
      "package_count": 2,
      "status": "OUT_FOR_DELIVERY",
      "assigned_courier_id": "uuid",
      "receiver_name": "Receiver Name",
      "receiver_address": "Street, City",
      "latitude": -6.9,
      "longitude": 110.4,
      "packages": [
        {
          "id": "uuid",
          "resi": "NEKO-2026-ABCD",
          "receiver_name": "Receiver Name",
          "receiver_address": "Street, City",
          "status": "OUT_FOR_DELIVERY",
          "latitude": -6.9,
          "longitude": 110.4
        }
      ]
    }
  ]
}
```

## 2. Task Detail

`GET /api/courier/tasks/:id`

Returns one bag with its package list.

Use this endpoint for a detail page that shows:

- bag code
- destination city
- assigned courier id
- package list inside the bag
- coordinates for the representative package

## 3. Bag Timeline

`GET /api/courier/tasks/:id/timeline`

Returns the bag plus a timeline per package.

Response shape:

```json
{
  "data": {
    "bag": {
      "id": "uuid",
      "bag_code": "BAG-2026-1A2B",
      "destination_city": "Semarang",
      "status": "OUT_FOR_DELIVERY",
      "assigned_courier_id": "uuid"
    },
    "packages": [
      {
        "id": "uuid",
        "resi": "NEKO-2026-ABCD",
        "receiver_name": "Receiver Name",
        "receiver_address": "Street, City",
        "status": "OUT_FOR_DELIVERY",
        "latitude": -6.9,
        "longitude": 110.4,
        "timeline": [
          {
            "event_code": "IN_WAREHOUSE",
            "event_label": "Di bagging",
            "location": "Semarang",
            "description": "Masuk ke bagging BAG-2026-1A2B",
            "created_at": "2026-05-07T00:00:00.000Z"
          }
        ]
      }
    ]
  }
}
```

## 4. Deliver Update

`PUT /api/courier/tasks/:id/deliver`

Body:

```json
{
  "status": "DELIVERED",
  "pod_image_url": "https://...",
  "courier_latitude": -6.9,
  "courier_longitude": 110.4,
  "target_latitude": -6.9,
  "target_longitude": 110.4,
  "delivered_at": "2026-05-07T00:00:00.000Z"
}
```

Behavior:

- Updates the package to `DELIVERED`.
- Inserts a POD tracking history row.
- Marks the parent bag `DELIVERED` when all packages in the bag are delivered.

## 5. Important Integration Notes

- Courier task list is bag-based, not package-list-based.
- The Flutter UI should render one bag card with nested package rows.
- A bag can contain multiple package timelines, so detail pages should group by bag first.
- The backend rejects delivery for a bag assigned to a different courier.