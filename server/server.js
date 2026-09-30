const path = require('path');
const express = require('express');
const compression = require('compression');
const dataRoutes = require('./data-routes');

const app = express();
app.use(compression());
app.use(express.json());
app.use('/api', dataRoutes);
app.use(express.static(path.join(__dirname, '..', 'public')));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`OAV ERP server running at http://localhost:${PORT}`);
});
