import { Router } from 'express';

const router = Router();

router.get('/', (req, res) => {
  res.json({ message: 'Training Plans route' });
});

export default router; 