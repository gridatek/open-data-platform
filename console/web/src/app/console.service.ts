import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { PolicySummary, ServiceStatus } from './models';

/** Read-only client for the console API (see console/api). */
@Injectable({ providedIn: 'root' })
export class ConsoleService {
  private readonly http = inject(HttpClient);

  services(): Observable<ServiceStatus[]> {
    return this.http.get<ServiceStatus[]>('/api/services');
  }

  namespaces(): Observable<string[]> {
    return this.http.get<string[]>('/api/catalog/namespaces');
  }

  policies(): Observable<PolicySummary[]> {
    return this.http.get<PolicySummary[]>('/api/policies');
  }
}
