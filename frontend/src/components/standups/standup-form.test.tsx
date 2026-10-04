import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';

const mutateAsync = vi.fn().mockResolvedValue({});

vi.mock('@/hooks/use-standups', () => ({
  useCreateStandup: () => ({ mutateAsync, isPending: false }),
  useUpdateStandup: () => ({ mutateAsync, isPending: false }),
}));

vi.mock('@/components/ui/use-toast', () => ({
  useToast: () => ({ toast: vi.fn() }),
}));

import { StandupForm } from './standup-form';

beforeEach(() => {
  mutateAsync.mockClear();
});

describe('StandupForm', () => {
  it('renders the three fields and both actions', () => {
    render(<StandupForm teamSlug="demo-team" />);

    expect(screen.getByLabelText(/yesterday/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/today/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/blockers/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /save draft/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /submit standup/i })).toBeInTheDocument();
  });

  it('shows validation errors when submitting an empty standup', async () => {
    render(<StandupForm teamSlug="demo-team" />);

    fireEvent.click(screen.getByRole('button', { name: /submit standup/i }));

    expect(await screen.findByText(/provide more details about yesterday/i)).toBeInTheDocument();
    expect(mutateAsync).not.toHaveBeenCalled();
  });
});
