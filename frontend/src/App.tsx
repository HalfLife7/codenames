import React from 'react';
import { ApolloClient, InMemoryCache, ApolloProvider } from '@apollo/client';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { io } from 'socket.io-client';

// Initialize Apollo Client
const client = new ApolloClient({
  uri: process.env.REACT_APP_HASURA_GRAPHQL_URL,
  cache: new InMemoryCache(),
});

// Initialize Socket.io client
const socket = io(process.env.REACT_APP_WS_URL || 'ws://localhost:4000');

function App() {
  return (
    <ApolloProvider client={client}>
      <Router>
        <div className="min-h-screen bg-gray-100">
          <Routes>
            <Route path="/" element={<div className="p-4">Welcome to your app!</div>} />
          </Routes>
        </div>
      </Router>
    </ApolloProvider>
  );
}

export default App; 