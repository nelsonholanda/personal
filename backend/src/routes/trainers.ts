import { Router } from 'express';

const router = Router();

router.get('/', (req, res) => {
  res.json({ message: 'Trainers route' });
});

export default router; 