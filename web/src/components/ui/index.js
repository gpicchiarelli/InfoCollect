export function Input({ ...props }) {
  return <input {...props} className="border rounded px-2 py-1 w-full" />;
}

export function Button({ children, ...props }) {
  return (
    <button
      {...props}
      className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
    >
      {children}
    </button>
  );
}

export function Card({ children }) {
  return <div className="border rounded shadow-sm">{children}</div>;
}
