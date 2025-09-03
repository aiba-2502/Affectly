import Link from 'next/link';

export default function InformationLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <Link href="/" className="text-xl font-bold text-gray-900">
                心のログ
              </Link>
            </div>
            <nav className="flex items-center space-x-4">
              <Link
                href="/login"
                className="text-sm text-gray-700 hover:text-gray-900"
              >
                ログイン
              </Link>
              <Link
                href="/signup"
                className="px-4 py-2 text-sm text-white bg-pink-600 rounded-md hover:bg-pink-700"
              >
                新規登録
              </Link>
            </nav>
          </div>
        </div>
      </header>
      {children}
    </>
  );
}