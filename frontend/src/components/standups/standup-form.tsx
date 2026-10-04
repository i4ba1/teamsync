'use client';

import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Loader2, Save, Send } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { useStandupStore } from '@/stores/standup-store';
import { useCreateStandup, useUpdateStandup } from '@/hooks/use-standups';
import { useToast } from '@/components/ui/use-toast';
import { Standup } from '@/types';

const standupSchema = z.object({
  yesterday: z.string().min(10, 'Please provide more details about yesterday'),
  today: z.string().min(10, 'What are you working on today?'),
  blockers: z.string().optional(),
});

type StandupFormData = z.infer<typeof standupSchema>;

interface StandupFormProps {
  teamSlug: string;
  standup?: Standup;
}

const textareaClass =
  'min-h-[100px] bg-slate-800 border-slate-700 text-white placeholder:text-slate-500 resize-none';

export function StandupForm({ teamSlug, standup }: StandupFormProps) {
  const { draft, setDraft, clearDraft } = useStandupStore();
  const { toast } = useToast();

  const createStandup = useCreateStandup(teamSlug);
  const updateStandup = useUpdateStandup(teamSlug, standup?.id || '');

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isDirty },
  } = useForm<StandupFormData>({
    resolver: zodResolver(standupSchema),
    defaultValues: {
      yesterday: draft.yesterday || standup?.itemsSummary?.yesterday?.join('\n') || '',
      today: draft.today || standup?.itemsSummary?.today?.join('\n') || '',
      blockers: draft.blockers || standup?.itemsSummary?.blockers?.join('\n') || '',
    },
  });

  const watchedValues = watch();

  useEffect(() => {
    const interval = setInterval(() => {
      if (isDirty) {
        setDraft(watchedValues);
      }
    }, 30000);

    return () => clearInterval(interval);
  }, [isDirty, watchedValues, setDraft]);

  const save = async (data: StandupFormData, submit: boolean) => {
    try {
      if (standup?.id) {
        await updateStandup.mutateAsync({ ...data, submit });
      } else {
        await createStandup.mutateAsync({ ...data, submit });
      }

      if (submit) {
        toast({
          title: 'Standup submitted!',
          description: 'Your standup has been submitted successfully.',
        });
        clearDraft();
      } else {
        toast({
          title: 'Draft saved',
          description: 'Your standup draft has been saved.',
        });
      }
    } catch {
      toast({
        variant: 'destructive',
        title: 'Error',
        description: 'Failed to save standup. Please try again.',
      });
    }
  };

  const isSubmitting = createStandup.isPending || updateStandup.isPending;
  const onSaveDraft = handleSubmit((data) => save(data, false));
  const onSubmitStandup = handleSubmit((data) => save(data, true));

  return (
    <Card className="border-slate-800 bg-slate-900/50">
      <CardHeader>
        <CardTitle className="text-white">Today&apos;s Standup</CardTitle>
      </CardHeader>
      <form onSubmit={(event) => event.preventDefault()}>
        <CardContent className="space-y-6">
          <div className="space-y-2">
            <Label htmlFor="yesterday" className="text-slate-300">
              Yesterday
            </Label>
            <Textarea
              id="yesterday"
              placeholder="What did you accomplish yesterday?"
              className={textareaClass}
              {...register('yesterday')}
            />
            {errors.yesterday && <p className="text-sm text-red-500">{errors.yesterday.message}</p>}
            <p className="text-xs text-slate-500">{watch('yesterday')?.length || 0} characters</p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="today" className="text-slate-300">
              Today
            </Label>
            <Textarea
              id="today"
              placeholder="What are you working on today?"
              className={textareaClass}
              {...register('today')}
            />
            {errors.today && <p className="text-sm text-red-500">{errors.today.message}</p>}
            <p className="text-xs text-slate-500">{watch('today')?.length || 0} characters</p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="blockers" className="text-slate-300">
              Blockers <span className="text-slate-500">(optional)</span>
            </Label>
            <Textarea
              id="blockers"
              placeholder="Anything blocking you?"
              className={textareaClass}
              {...register('blockers')}
            />
            {errors.blockers && <p className="text-sm text-red-500">{errors.blockers.message}</p>}
            <p className="text-xs text-slate-500">{watch('blockers')?.length || 0} characters</p>
          </div>
        </CardContent>

        <CardFooter className="flex items-center justify-between border-t border-slate-800 pt-6">
          <Button
            type="button"
            variant="outline"
            disabled={isSubmitting}
            onClick={onSaveDraft}
            className="border-slate-700 bg-transparent text-slate-200 hover:bg-slate-800"
          >
            {isSubmitting ? (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            ) : (
              <Save className="mr-2 h-4 w-4" />
            )}
            Save Draft
          </Button>
          <Button type="button" disabled={isSubmitting} onClick={onSubmitStandup}>
            {isSubmitting ? (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            ) : (
              <Send className="mr-2 h-4 w-4" />
            )}
            Submit Standup
          </Button>
        </CardFooter>
      </form>
    </Card>
  );
}
