function WeatherFeedback({ location }) {
    const [type, setType] = useState("AccuracyReport");
    const [message, setMessage] = useState("");
    const [isPriority, setIsPriority] = useState(false);
    const [location, setLocation] = useState(null);
  
    const submit = async () => {
      const feedbackType = switch (type) {
        case "AccuracyReport" => {
          #AccuracyReport: {
            expectedWeather: prompt("What weather did you expect?"),
            actualWeather: prompt("What weather occurred?")
          }
        };
        case _ => #{ #GeneralFeedback: message };
      };
  
      await actor.submit_feedback(feedbackType, location, isPriority);
    };

    useEffect(() => {
        navigator.geolocation.getCurrentPosition(
          (pos) => setLocation({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
          (err) => console.warn("Location denied")
        );
      }, []);
      <WeatherFeedback location={location} />
  
    return (
      <div>
        <select onChange={(e) => setType(e.target.value)}>
          <option value="AccuracyReport">Report Inaccuracy</option>
          <option value="FeatureRequest">Request Feature</option>
          <option value="GeneralFeedback">General Feedback</option>
        </select>
        {type === "GeneralFeedback" && (
          <textarea onChange={(e) => setMessage(e.target.value)} />
        )}
        <label>
          <input type="checkbox" checked={isPriority} onChange={() => setIsPriority(!isPriority)} />
          Urgent (e.g., dangerous forecast error)
        </label>
        <button onClick={submit}>Submit</button>
      </div>
    );
  }