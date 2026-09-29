# 🛠️ Developer Integration Guide: Enabling Centralized Maintenance Mode in Your Applications

This guide provides step-by-step instructions and copy-pasteable code recipes for developers deploying applications on **VPS-Infra** to participate in the platform's **Centralized Maintenance Mode**.

---

## 1. How Maintenance Mode Works

When a DevOps administrator toggles **Maintenance Mode** for your service in the **DevOps Manager UI** (`https://devops.yourdomain.com`):

```
                        ┌──────────────────────────────────────────────┐
                        │      DevOps Manager UI / Admin Toggle        │
                        └──────────────────────┬───────────────────────┘
                                               │
               ┌───────────────────────────────┴───────────────────────────────┐
               ▼                                                               ▼
   [Web Trapped Interceptor]                                      [Backend Container Environment]
   • Global Axios/Fetch Interceptor                              • SystemStatus__IsMaintenance=true
   • Displays <MaintenanceOverlay />                             • SystemStatus__StatusMessage="Upgrading..."
   • "Check Again" zero-reload restore                           • SystemStatus__ShowMaintenanceForWeb=true
                                                                 • SystemStatus__ShowMaintenanceForMobile=true
                                                                               │
                                                                               ▼
                                                                ┌──────────────────────────────┐
                                                                │  Your Backend Middleware     │
                                                                └──────────────┬───────────────┘
                                                                               │
                                            ┌──────────────────────────────────┴──────────────────────────────────┐
                                            ▼                                                                     ▼
                                ┌───────────────────────────────┐                                     ┌───────────────────────────────┐
                                │   Always Allowed (HTTP 200)   │                                     │  Protected Business Routes    │
                                │   • GET /health               │                                     │  • GET /api/orders            │
                                │   • GET /healthz              │                                     │  • POST /api/checkout         │
                                │   • GET /api/system/status    │                                     │  ──> HTTP 503 Unavailable     │
                                └───────────────────────────────┘                                     └───────────────────────────────┘
```

---

## 2. Developer Contract Checklist

To integrate with Centralized Maintenance Mode, your applications need to follow this **3-point contract**:

| Component | Responsibility | Action Required |
|---|---|---|
| **Backend API** | Intercept requests when active | Read `SystemStatus__IsMaintenance`, keep `/health` & `/api/system/status` working (`200 OK`), return `HTTP 503` on all other endpoints. |
| **Frontend Web** | Display maintenance overlay | Catch `503` in HTTP interceptor, mount `<MaintenanceOverlay />` at app root, provide a "Check Again" button. |
| **Mobile App** | Prevent broken sessions | Check `/api/system/status` on app start/resume, catch `503` in network client, show non-dismissible dialog. |

---

## 3. Backend API Implementation Recipes

### Option A: ASP.NET Core (.NET 8 / 9 / 10)

#### 1. Add `SystemStatusDto.cs`:
```csharp
namespace YourApp.DTOs;

public class SystemStatusDto
{
    public bool IsMaintenance { get; set; } = false;
    public string StatusMessage { get; set; } = "System is operational.";
    public string Version { get; set; } = "1.0.0";
    public bool ShowMaintenanceForMobile { get; set; } = true;
    public bool ShowMaintenanceForWeb { get; set; } = true;
}
```

#### 2. Add `MaintenanceModeMiddleware.cs`:
```csharp
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using YourApp.DTOs;

namespace YourApp.Middlewares;

public class MaintenanceModeMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IConfiguration _config;
    private static readonly string[] AllowedPaths = { "/health", "/healthz", "/api/system/status" };

    public MaintenanceModeMiddleware(RequestDelegate next, IConfiguration config)
    {
        _next = next;
        _config = config;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var path = context.Request.Path.Value?.ToLowerInvariant() ?? "";

        // 1. Bypass health checks and status endpoints
        if (AllowedPaths.Any(p => path.StartsWith(p)))
        {
            await _next(context);
            return;
        }

        // 2. Check maintenance state from environment / configuration
        bool isMaintenance = _config.GetValue<bool>("SystemStatus:IsMaintenance");
        if (isMaintenance)
        {
            context.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
            context.Response.ContentType = "application/json";

            var payload = new SystemStatusDto
            {
                IsMaintenance = true,
                StatusMessage = _config.GetValue<string>("SystemStatus:StatusMessage") 
                    ?? "The system is currently undergoing scheduled maintenance. Please check back shortly.",
                ShowMaintenanceForWeb = _config.GetValue<bool>("SystemStatus:ShowMaintenanceForWeb", true),
                ShowMaintenanceForMobile = _config.GetValue<bool>("SystemStatus:ShowMaintenanceForMobile", true)
            };

            await context.Response.WriteAsJsonAsync(payload);
            return;
        }

        await _next(context);
    }
}
```

#### 3. Expose `SystemStatusController.cs`:
```csharp
using Microsoft.AspNetCore.Mvc;
using YourApp.DTOs;

namespace YourApp.Controllers;

[ApiController]
[Route("api/system")]
public class SystemController : ControllerBase
{
    private readonly IConfiguration _config;

    public SystemController(IConfiguration config) => _config = config;

    [HttpGet("status")]
    public IActionResult GetStatus()
    {
        return Ok(new SystemStatusDto
        {
            IsMaintenance = _config.GetValue<bool>("SystemStatus:IsMaintenance"),
            StatusMessage = _config.GetValue<string>("SystemStatus:StatusMessage") ?? "System is operational.",
            ShowMaintenanceForWeb = _config.GetValue<bool>("SystemStatus:ShowMaintenanceForWeb", true),
            ShowMaintenanceForMobile = _config.GetValue<bool>("SystemStatus:ShowMaintenanceForMobile", true)
        });
    }
}
```

#### 4. Register in `Program.cs`:
```csharp
// Place MaintenanceModeMiddleware right before app.MapControllers()
app.UseMiddleware<MaintenanceModeMiddleware>();

app.MapControllers();
app.MapHealthChecks("/health");
```

---

### Option B: Node.js (Express)

#### 1. Add `maintenanceMiddleware.js`:
```javascript
const ALLOWED_PATHS = ['/health', '/healthz', '/api/system/status'];

export function maintenanceMiddleware(req, res, next) {
  const isMaintenance = process.env.SYSTEM_STATUS_IS_MAINTENANCE === 'true' || 
                        process.env.SystemStatus__IsMaintenance === 'true';

  // Always allow health and status probes
  if (ALLOWED_PATHS.some(p => req.path.toLowerCase().startsWith(p))) {
    return next();
  }

  if (isMaintenance) {
    const statusMessage = process.env.SYSTEM_STATUS_STATUS_MESSAGE || 
                          process.env.SystemStatus__StatusMessage || 
                          'System is currently undergoing scheduled maintenance.';

    return res.status(503).json({
      isMaintenance: true,
      statusMessage,
      showMaintenanceForWeb: true,
      showMaintenanceForMobile: true
    });
  }

  next();
}
```

#### 2. Register in `server.js`:
```javascript
import express from 'express';
import { maintenanceMiddleware } from './maintenanceMiddleware.js';

const app = express();

// Status endpoint (always 200 OK)
app.get('/api/system/status', (req, res) => {
  const isMaintenance = process.env.SYSTEM_STATUS_IS_MAINTENANCE === 'true' || process.env.SystemStatus__IsMaintenance === 'true';
  const statusMessage = process.env.SYSTEM_STATUS_STATUS_MESSAGE || 'System is operational.';
  res.json({ isMaintenance, statusMessage, showMaintenanceForWeb: true, showMaintenanceForMobile: true });
});

// Health check endpoint
app.get('/health', (req, res) => res.json({ status: 'healthy' }));

// Apply maintenance interceptor for all business routes
app.use(maintenanceMiddleware);

// Your regular application routes
app.use('/api/orders', orderRouter);
```

---

### Option C: Python (FastAPI)

```python
import os
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()

ALLOWED_PATHS = ["/health", "/healthz", "/api/system/status"]

@app.middleware("http")
async def maintenance_middleware(request: Request, call_next):
    path = request.url.path.lower()
    is_maintenance = os.getenv("SystemStatus__IsMaintenance", "false").lower() == "true" or \
                     os.getenv("SYSTEM_STATUS_IS_MAINTENANCE", "false").lower() == "true"

    if any(path.startswith(p) for p in ALLOWED_PATHS):
        return await call_next(request)

    if is_maintenance:
        message = os.getenv("SystemStatus__StatusMessage", "System is undergoing maintenance.")
        return JSONResponse(
            status_code=503,
            content={
                "isMaintenance": True,
                "statusMessage": message,
                "showMaintenanceForWeb": True,
                "showMaintenanceForMobile": True
            }
        )

    return await call_next(request)

@app.get("/api/system/status")
async def get_system_status():
    is_maint = os.getenv("SystemStatus__IsMaintenance", "false").lower() == "true"
    message = os.getenv("SystemStatus__StatusMessage", "System is operational.")
    return {"isMaintenance": is_maint, "statusMessage": message, "showMaintenanceForWeb": True, "showMaintenanceForMobile": True}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

---

## 4. Frontend Web Implementation (React / Vite / Angular)

### 1. Axios Response Interceptor (`src/services/api.ts`):
Trap `HTTP 503` responses globally and dispatch a maintenance event:

```typescript
import axios from 'axios';

export const api = axios.create({ baseURL: import.meta.env.VITE_API_URL });

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 503) {
      const data = error.response.data;
      const isMaint = data?.isMaintenance ?? true;
      const message = data?.statusMessage || data?.message || 'Scheduled maintenance is in progress.';
      
      // Notify MaintenanceOverlay
      window.dispatchEvent(new CustomEvent('SYSTEM_MAINTENANCE_MODE', {
        detail: { isMaintenance: isMaint, message }
      }));
    }
    return Promise.reject(error);
  }
);
```

### 2. `<MaintenanceOverlay />` Component (`src/components/MaintenanceOverlay.tsx`):
Mount this component in your root layout (`src/App.tsx`). It displays a non-dismissible modal with an automated **"Check Again"** button:

```tsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';

export const MaintenanceOverlay: React.FC = () => {
  const [isMaintenance, setIsMaintenance] = useState(false);
  const [message, setMessage] = useState('');
  const [checking, setChecking] = useState(false);

  useEffect(() => {
    // 1. Initial check on page load
    checkStatus();

    // 2. Listen to 503 network interceptor events
    const handleEvent = (e: any) => {
      setIsMaintenance(e.detail.isMaintenance);
      setMessage(e.detail.message);
    };

    window.addEventListener('SYSTEM_MAINTENANCE_MODE', handleEvent);
    return () => window.removeEventListener('SYSTEM_MAINTENANCE_MODE', handleEvent);
  }, []);

  const checkStatus = async () => {
    try {
      setChecking(true);
      const res = await axios.get(`${import.meta.env.VITE_API_URL}/api/system/status`);
      if (res.data?.isMaintenance) {
        setIsMaintenance(true);
        setMessage(res.data.statusMessage || 'System maintenance in progress.');
      } else {
        setIsMaintenance(false);
      }
    } catch {
      // If server unreachable, keep maintenance active
    } finally {
      setChecking(false);
    }
  };

  if (!isMaintenance) return null;

  return (
    <div style={{
      position: 'fixed', inset: 0, zIndex: 999999,
      backgroundColor: 'rgba(15, 23, 42, 0.95)',
      backdropFilter: 'blur(8px)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1.5rem',
      fontFamily: 'Inter, system-ui, sans-serif'
    }}>
      <div style={{
        maxWidth: '480px', width: '100%',
        backgroundColor: '#1E293B', border: '1px solid #334155',
        borderRadius: '1.25rem', padding: '2rem', textAlign: 'center', color: '#F8FAFC',
        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)'
      }}>
        <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>🔧</div>
        <span style={{
          display: 'inline-block', padding: '0.25rem 0.75rem', borderRadius: '9999px',
          fontSize: '0.75rem', fontWeight: 700, backgroundColor: 'rgba(245, 158, 11, 0.15)',
          color: '#FBBF24', border: '1px solid rgba(245, 158, 11, 0.3)', marginBottom: '1rem'
        }}>
          SCHEDULED MAINTENANCE
        </span>
        <h2 style={{ fontSize: '1.5rem', fontWeight: 800, margin: '0 0 0.5rem 0' }}>
          System Under Maintenance
        </h2>
        <p style={{ color: '#94A3B8', fontSize: '0.875rem', lineHeight: 1.6, marginBottom: '1.5rem' }}>
          {message}
        </p>
        <button
          onClick={checkStatus}
          disabled={checking}
          style={{
            width: '100%', padding: '0.75rem 1.5rem', borderRadius: '0.75rem',
            backgroundColor: '#0284C7', color: 'white', fontWeight: 600, fontSize: '0.875rem',
            border: 'none', cursor: checking ? 'not-allowed' : 'pointer',
            opacity: checking ? 0.7 : 1, transition: 'background-color 0.2s'
          }}
        >
          {checking ? 'Checking Status...' : 'Check Again'}
        </button>
      </div>
    </div>
  );
};
```

---

## 5. Mobile App Implementation (Flutter & React Native)

### Option A: Flutter (Dart with `Dio`)

#### 1. Dio Interceptor (`lib/core/network/maintenance_interceptor.dart`):
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final maintenanceProvider = StateNotifierProvider<MaintenanceNotifier, MaintenanceState>((ref) {
  return MaintenanceNotifier();
});

class MaintenanceState {
  final bool isMaintenance;
  final String message;
  MaintenanceState({this.isMaintenance = false, this.message = ''});
}

class MaintenanceNotifier extends StateNotifier<MaintenanceState> {
  MaintenanceNotifier() : super(MaintenanceState());

  void setMaintenance(bool active, String message) {
    state = MaintenanceState(isMaintenance: active, message: message);
  }

  Future<void> checkStatus(Dio dio, String baseUrl) async {
    try {
      final res = await dio.get('$baseUrl/api/system/status');
      if (res.data != null && res.data['isMaintenance'] == true) {
        state = MaintenanceState(
          isMaintenance: true,
          message: res.data['statusMessage'] ?? 'Maintenance in progress.',
        );
      } else {
        state = MaintenanceState(isMaintenance: false, message: '');
      }
    } catch (_) {}
  }
}

class MaintenanceInterceptor extends Interceptor {
  final Ref ref;
  MaintenanceInterceptor(this.ref);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 503) {
      String msg = 'System is undergoing scheduled maintenance.';
      final data = err.response?.data;
      if (data is Map && data['statusMessage'] != null) {
        msg = data['statusMessage'].toString();
      }
      ref.read(maintenanceProvider.notifier).setMaintenance(true, msg);
    }
    handler.next(err);
  }
}
```

#### 2. Root Widget Integration (`lib/app.dart`):
Wrap your `MaterialApp` with `MaintenanceOverlay` and block the Android hardware back button:

```dart
class MaintenanceOverlayWidget extends ConsumerWidget {
  final Widget child;
  const MaintenanceOverlayWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(maintenanceProvider);

    return Stack(
      children: [
        child,
        if (state.isMaintenance)
          PopScope(
            canPop: false, // Prevents closing via Android Back Button
            child: Scaffold(
              backgroundColor: const Color(0xFF0F172A),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.build_circle_outlined, size: 72, color: Colors.amber),
                      const SizedBox(height: 16),
                      const Text(
                        "Under Maintenance",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => ref.read(maintenanceProvider.notifier).checkStatus(dio, baseUrl),
                        child: const Text("Check Again"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

---

### Option B: React Native / Expo

```typescript
import React, { useState, useEffect } from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import axios from 'axios';

export const MaintenanceModal = ({ apiUrl }: { apiUrl: string }) => {
  const [visible, setVisible] = useState(false);
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    checkStatus();

    // Setup Axios 503 Interceptor
    const interceptor = axios.interceptors.response.use(
      res => res,
      err => {
        if (err.response?.status === 503) {
          setMessage(err.response.data?.statusMessage || 'Scheduled maintenance in progress.');
          setVisible(true);
        }
        return Promise.reject(err);
      }
    );

    return () => axios.interceptors.response.eject(interceptor);
  }, []);

  const checkStatus = async () => {
    try {
      setLoading(true);
      const res = await axios.get(`${apiUrl}/api/system/status`);
      if (res.data?.isMaintenance) {
        setMessage(res.data.statusMessage || 'Maintenance in progress.');
        setVisible(true);
      } else {
        setVisible(false);
      }
    } catch {} finally {
      setLoading(false);
    }
  };

  return (
    <Modal visible={visible} animationType="fade" transparent={false}>
      <View style={styles.container}>
        <Text style={styles.icon}>🔧</Text>
        <Text style={styles.title}>System Under Maintenance</Text>
        <Text style={styles.message}>{message}</Text>
        <TouchableOpacity style={styles.button} onPress={checkStatus} disabled={loading}>
          <Text style={styles.buttonText}>{loading ? 'Checking...' : 'Check Again'}</Text>
        </TouchableOpacity>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0F172A', justifyContent: 'center', alignItems: 'center', padding: 24 },
  icon: { fontSize: 64, marginBottom: 16 },
  title: { fontSize: 22, fontWeight: 'bold', color: '#FFFFFF', marginBottom: 12 },
  message: { fontSize: 14, color: '#94A3B8', textAlign: 'center', marginBottom: 24, lineHeight: 20 },
  button: { backgroundColor: '#0284C7', paddingHorizontal: 32, paddingVertical: 14, borderRadius: 12 },
  buttonText: { color: '#FFFFFF', fontWeight: 'bold', fontSize: 16 }
});
```

---

## 6. Testing Your Maintenance Integration

1. Start your backend container with maintenance enabled:
   ```bash
   docker run -e SystemStatus__IsMaintenance=true -p 8080:8080 your-api:latest
   ```
2. Test the endpoints:
   ```bash
   # 1. Status endpoint MUST return 200 OK
   curl -i http://localhost:8080/api/system/status

   # 2. Health endpoint MUST return 200 OK
   curl -i http://localhost:8080/health

   # 3. Any business endpoint MUST return 503 Service Unavailable
   curl -i http://localhost:8080/api/orders
   ```
3. Open your web frontend or mobile app:
   - Verify the `<MaintenanceOverlay />` immediately renders with the custom message.
   - Test the **"Check Again"** button after setting `SystemStatus__IsMaintenance=false` to ensure zero-reload recovery.
