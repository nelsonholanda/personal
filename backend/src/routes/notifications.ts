import { Router } from 'express';

const router = Router();

router.get('/', (req, res) => {
  res.json({ message: 'Notifications route' });
});

export default router; 