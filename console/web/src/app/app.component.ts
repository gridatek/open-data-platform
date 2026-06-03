import { CommonModule } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { ConsoleService } from './console.service';
import { PolicySummary, ServiceStatus } from './models';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule],
  template: `
    <header class="border-b border-slate-200 bg-white">
      <div class="mx-auto max-w-5xl px-6 py-4">
        <h1 class="text-xl font-semibold">Open Data Platform — Console</h1>
        <p class="text-sm text-slate-500">Read-only control plane (Phase 2 MVP)</p>
      </div>
    </header>

    <main class="mx-auto max-w-5xl space-y-8 px-6 py-8">
      <!-- Services & health -->
      <section>
        <h2 class="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-500">Services</h2>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">
          <div
            *ngFor="let s of services()"
            class="flex items-center justify-between rounded-lg border border-slate-200 bg-white px-4 py-3"
          >
            <span class="font-medium">{{ s.name }}</span>
            <span
              class="rounded-full px-2 py-0.5 text-xs font-semibold"
              [class.bg-green-100]="s.status === 'UP'"
              [class.text-green-700]="s.status === 'UP'"
              [class.bg-red-100]="s.status !== 'UP'"
              [class.text-red-700]="s.status !== 'UP'"
              [title]="s.detail"
              >{{ s.status }}</span
            >
          </div>
          <p *ngIf="services().length === 0" class="text-sm text-slate-400">No services reported.</p>
        </div>
      </section>

      <!-- Catalog -->
      <section>
        <h2 class="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-500">
          Iceberg namespaces
        </h2>
        <ul class="flex flex-wrap gap-2">
          <li
            *ngFor="let ns of namespaces()"
            class="rounded-md border border-slate-200 bg-white px-3 py-1 text-sm"
          >
            {{ ns }}
          </li>
          <li *ngIf="namespaces().length === 0" class="text-sm text-slate-400">
            Catalog unavailable.
          </li>
        </ul>
      </section>

      <!-- Policies -->
      <section>
        <h2 class="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-500">
          Ranger policies
        </h2>
        <table class="w-full overflow-hidden rounded-lg border border-slate-200 bg-white text-sm">
          <thead class="bg-slate-100 text-left text-slate-500">
            <tr>
              <th class="px-4 py-2 font-medium">Name</th>
              <th class="px-4 py-2 font-medium">Type</th>
              <th class="px-4 py-2 font-medium">Enabled</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let p of policies()" class="border-t border-slate-100">
              <td class="px-4 py-2">{{ p.name }}</td>
              <td class="px-4 py-2">{{ p.type }}</td>
              <td class="px-4 py-2">{{ p.enabled ? 'yes' : 'no' }}</td>
            </tr>
            <tr *ngIf="policies().length === 0">
              <td class="px-4 py-3 text-slate-400" colspan="3">No policies (Ranger unavailable).</td>
            </tr>
          </tbody>
        </table>
      </section>
    </main>
  `,
})
export class AppComponent implements OnInit {
  private readonly console = inject(ConsoleService);

  readonly services = signal<ServiceStatus[]>([]);
  readonly namespaces = signal<string[]>([]);
  readonly policies = signal<PolicySummary[]>([]);

  ngOnInit(): void {
    this.console.services().subscribe({ next: (v) => this.services.set(v), error: () => {} });
    this.console.namespaces().subscribe({ next: (v) => this.namespaces.set(v), error: () => {} });
    this.console.policies().subscribe({ next: (v) => this.policies.set(v), error: () => {} });
  }
}
