import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Output, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ConsoleService } from './console.service';

/**
 * Create a Ranger column-masking policy from a small form. Builds the raw Ranger
 * policy document (policyType 1 + dataMaskPolicyItems) and POSTs it via the
 * console API. Emits `created` so the parent can refresh the policy list.
 */
@Component({
  selector: 'app-policy-editor',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  template: `
    <details class="rounded-lg border border-slate-200 bg-white">
      <summary class="cursor-pointer px-4 py-3 text-sm font-medium text-slate-700">
        + New masking policy
      </summary>

      <form [formGroup]="form" (ngSubmit)="submit()" class="space-y-4 border-t border-slate-100 p-4">
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">
          <label class="block text-xs">
            <span class="mb-1 block font-medium text-slate-500">Name</span>
            <input formControlName="name" class="w-full rounded-md border border-slate-300 px-2 py-1" />
          </label>
          <label class="block text-xs">
            <span class="mb-1 block font-medium text-slate-500">Catalog</span>
            <input formControlName="catalog" class="w-full rounded-md border border-slate-300 px-2 py-1" />
          </label>
          <label class="block text-xs">
            <span class="mb-1 block font-medium text-slate-500">Schema</span>
            <input formControlName="schema" class="w-full rounded-md border border-slate-300 px-2 py-1" />
          </label>
          <label class="block text-xs">
            <span class="mb-1 block font-medium text-slate-500">Table</span>
            <input formControlName="table" class="w-full rounded-md border border-slate-300 px-2 py-1" />
          </label>
          <label class="block text-xs">
            <span class="mb-1 block font-medium text-slate-500">Column</span>
            <input formControlName="column" class="w-full rounded-md border border-slate-300 px-2 py-1" />
          </label>
          <label class="block text-xs">
            <span class="mb-1 block font-medium text-slate-500">Mask for user</span>
            <input formControlName="user" class="w-full rounded-md border border-slate-300 px-2 py-1" />
          </label>
          <label class="block text-xs">
            <span class="mb-1 block font-medium text-slate-500">Mask type</span>
            <select formControlName="maskType" class="w-full rounded-md border border-slate-300 px-2 py-1">
              <option *ngFor="let m of maskTypes" [value]="m">{{ m }}</option>
            </select>
          </label>
        </div>

        <div class="flex items-center gap-3">
          <button
            type="submit"
            [disabled]="submitting() || form.invalid"
            class="rounded-md bg-slate-800 px-3 py-1.5 text-xs font-medium text-white hover:bg-slate-700 disabled:opacity-50"
          >
            {{ submitting() ? 'Creating…' : 'Create policy' }}
          </button>
          <span
            *ngIf="message() as m"
            class="text-xs"
            [class.text-green-600]="m.ok"
            [class.text-red-600]="!m.ok"
            >{{ m.text }}</span
          >
        </div>
      </form>
    </details>
  `,
})
export class PolicyEditorComponent {
  private readonly console = inject(ConsoleService);
  private readonly fb = inject(FormBuilder);

  @Output() created = new EventEmitter<void>();

  readonly submitting = signal(false);
  readonly message = signal<{ ok: boolean; text: string } | null>(null);

  readonly maskTypes = [
    'MASK',
    'MASK_SHOW_LAST_4',
    'MASK_SHOW_FIRST_4',
    'MASK_HASH',
    'MASK_NULL',
    'MASK_NONE',
    'MASK_DATE_SHOW_YEAR',
  ];

  readonly form = this.fb.nonNullable.group({
    name: ['mask-events-kind', Validators.required],
    catalog: ['iceberg', Validators.required],
    schema: ['smoke', Validators.required],
    table: ['events', Validators.required],
    column: ['kind', Validators.required],
    user: ['analyst', Validators.required],
    maskType: ['MASK', Validators.required],
  });

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const v = this.form.getRawValue();
    const resource = (value: string) => ({ values: [value], isExcludes: false, isRecursive: false });
    const doc = {
      service: 'trino-odp',
      name: v.name,
      policyType: 1,
      isEnabled: true,
      isAuditEnabled: true,
      resources: {
        catalog: resource(v.catalog),
        schema: resource(v.schema),
        table: resource(v.table),
        column: resource(v.column),
      },
      dataMaskPolicyItems: [
        {
          users: [v.user],
          accesses: [{ type: 'select', isAllowed: true }],
          dataMaskInfo: { dataMaskType: v.maskType },
        },
      ],
    };

    this.submitting.set(true);
    this.message.set(null);
    this.console.createPolicy(doc).subscribe({
      next: (p) => {
        this.submitting.set(false);
        this.message.set({ ok: true, text: `Created "${p.name}" (#${p.id}).` });
        this.created.emit();
      },
      error: () => {
        this.submitting.set(false);
        this.message.set({ ok: false, text: 'Create failed — is Ranger reachable?' });
      },
    });
  }
}
