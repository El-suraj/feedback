export default function FeedbackList({ feedbacks, isAdmin }) {
    return (
      <table>
        {feedbacks.map((fb) => (
          <tr key={fb.id}>
            <td>{fb.user}</td>
            <td>{renderFeedbackType(fb.feedbackType)}</td>
            <td>{fb.location ? `📍 ${fb.location.lat},${fb.location.lng}` : "No location"}</td>
          </tr>
        ))}
      </table>
    );
  }