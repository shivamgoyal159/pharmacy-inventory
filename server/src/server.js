const express = require('express')

const app = express()
const PORT = 5000

app.use(express.json())

app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Pharmacy Inventory API is running',
  })
})

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`)
})