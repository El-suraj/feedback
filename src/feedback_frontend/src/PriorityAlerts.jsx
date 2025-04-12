useEffect(() => {
    const fetchUrgentFeedback = async () => {
      const actor = await getFeedbackActor();
      const urgent = await actor.getPriorityFeedbacks();
      setAlerts(urgent);
    };
    fetchUrgentFeedback();
  }, []);