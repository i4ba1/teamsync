export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950">
      <div className="w-full max-w-md p-6">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-white mb-2">TeamSync</h1>
          <p className="text-slate-400">Async standups for remote teams</p>
        </div>
        {children}
      </div>
    </div>
  );
}
