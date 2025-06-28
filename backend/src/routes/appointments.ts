import { Router } from 'express';

const router = Router();

router.get('/', (req, res) => {
  res.json({ message: 'Appointments route' });
});

export default router; 