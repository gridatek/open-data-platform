import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { PolicySummary, ServiceStatus } from './models';

/** Client for the console API (see console/api). Reads, plus Phase 4 governance writes. */
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

  /** Enable/disable a Ranger policy — the Phase 4 control-plane action. */
  setPolicyEnabled(id: number, enabled: boolean): Observable<PolicySummary> {
    return this.http.post<PolicySummary>(`/api/policies/${id}/enabled`, { enabled });
  }
}
