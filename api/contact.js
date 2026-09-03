export default async function handler(req, res) {
  // Only allow POST
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { name, email, topic, message } = req.body;

    // Basic validation (mirrors frontend)
    if (!name || name.trim().length < 2) {
      return res.status(400).json({ error: 'Please enter your name.' });
    }
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return res.status(400).json({ error: 'Please enter a valid email.' });
    }
    if (!topic) {
      return res.status(400).json({ error: 'Please choose a topic.' });
    }
    if (!message || message.trim().length < 10) {
      return res.status(400).json({ error: 'Please write at least 10 characters.' });
    }

    // Log to Vercel console (visible in Vercel Dashboard → Logs)
    console.log('Contact form submission:', { name, email, topic, message });

    // In a real implementation you would send an email here.
    // For now, the message lands in the function log only. The success
    // string below is honest about that — the user is told exactly what
    // happened (logged) and what to do for time-sensitive mail (write
    // directly to the address). See harness/state/facts.md F011 and
    // harness/state/decisions.md D001 for the no-fabrication policy.
    //
    // Example (pseudo) once the email step is wired up:
    // await sendEmail({
    //   to: 'sachin@a-anie.example',
    //   subject: `[A-Anie Contact] ${topic} from ${name}`,
    //   text: `Name: ${name}\nEmail: ${email}\nTopic: ${topic}\n\nMessage:\n${message}`
    // });

    return res.status(200).json({
      message: 'Logged. I read these in the Vercel function log when I check the deploy. For anything time-sensitive, write directly to sachin@a-anie.example.'
    });
  } catch (err) {
    console.error('Contact form error:', err);
    return res.status(500).json({ error: 'Could not send. Please try again later.' });
  }
}