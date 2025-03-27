import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import React from 'react';

const mockPages = [
  { title: 'Pagina 1', url: 'http://example.com/1' },
  { title: 'Pagina 2', url: 'http://example.com/2' },
];

global.fetch = jest.fn(() =>
  Promise.resolve({
    json: () => Promise.resolve(mockPages),
  })
) as jest.Mock;

function Pages() {
  const [pages, setPages] = React.useState([]);
  React.useEffect(() => {
    fetch('/api/pages')
      .then((res) => res.json())
      .then(setPages);
  }, []);
  return (
    <ul>
      {pages.map((page, index) => (
        <li key={index}>
          {page.title} - <a href={page.url}>{page.url}</a>
        </li>
      ))}
    </ul>
  );
}

test('renders pages dynamically', async () => {
  render(<Pages />);
  const items = await screen.findAllByRole('listitem');
  expect(items).toHaveLength(mockPages.length);
});
