// src/backend/main.mo

import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Option "mo:base/Option";

actor FeedbackCanister {
  // ========== TYPES ==========
  public type FeedbackType = {
    #AccuracyReport : {
      expectedWeather : Text;
      actualWeather : Text;
    };
    #FeatureRequest : Text;
    #GeneralFeedback : Text;
  };

  public type Location = {
    lat : Float;
    lng : Float;
  };

  public type Feedback = {
    id : Nat;
    user : Principal;
    feedbackType : FeedbackType;
    location : ?Location;
    timestamp : Int;
    isPriority : Bool;
  };

  type RateLimit = {
    lastSubmissionTime : Int;
    submissionCount : Nat;
  };

  // ========== CONSTANTS ==========
  let RATE_LIMIT_WINDOW : Int = 3600; // 1 hour in seconds
  let MAX_SUBMISSIONS_PER_WINDOW : Nat = 3;

  // ========== STORAGE ==========
  stable var nextId : Nat = 0;
  stable var stableFeedbacks : [Feedback] = [];
  stable var stableRateLimits : [(Principal, RateLimit)] = [];

  var feedbacks : [Feedback] = stableFeedbacks;
  var rateLimits = HashMap.HashMap<Principal, RateLimit>(
    0, Principal.equal, Principal.hash
  );

  // ========== SYSTEM METHODS ==========
  system func preupgrade() {
    stableFeedbacks := feedbacks;
    stableRateLimits := HashMap.toArray(rateLimits);
  };

  system func postupgrade() {
    feedbacks := stableFeedbacks;
    rateLimits := HashMap.fromIter<Principal, RateLimit>(
      stableRateLimits.vals(), 0, Principal.equal, Principal.hash
    );
  };

  // ========== PUBLIC METHODS ==========
  public shared ({ caller }) func submitFeedback(
    feedbackType : FeedbackType,
    location : ?Location,
    isPriority : Bool
  ) : async () {
    // Check rate limit
    let now = Time.now();
    let userLimit = switch (rateLimits.get(caller)) {
      case (?limit) {
        if (now - limit.lastSubmissionTime < RATE_LIMIT_WINDOW) {
          assert(limit.submissionCount < adjustedMaxSubmissions(isPriority));
          {
            lastSubmissionTime = limit.lastSubmissionTime;
            submissionCount = limit.submissionCount + 1;
          };
        } else {
          // Reset counter if window expired
          { lastSubmissionTime = now; submissionCount = 1 };
        }
      };
      case null {
        // First submission
        { lastSubmissionTime = now; submissionCount = 1 };
      };
    };
    rateLimits.put(caller, userLimit);

    // Create and store feedback
    let newFeedback : Feedback = {
      id = nextId;
      user = caller;
      feedbackType;
      location;
      timestamp = now;
      isPriority;
    };

    feedbacks := Array.append(feedbacks, [newFeedback]);
    nextId += 1;
  };

  // ========== QUERY METHODS ==========
  public query func getAccuracyReports() : async [Feedback] {
    Array.filter(feedbacks, func (fb : Feedback) : Bool {
      switch (fb.feedbackType) {
        case (#AccuracyReport _) true;
        case _ false;
      };
    });
  };

  public query func getFeatureRequests() : async [Feedback] {
    Array.filter(feedbacks, func (fb : Feedback) : Bool {
      switch (fb.feedbackType) {
        case (#FeatureRequest _) true;
        case _ false;
      };
    });
  };

  public query func getPriorityFeedbacks() : async [Feedback] {
    Array.filter(feedbacks, func (fb : Feedback) : Bool {
      fb.isPriority;
    });
  };

  public query func getUserFeedbacks(user : Principal) : async [Feedback] {
    Array.filter(feedbacks, func (fb : Feedback) : Bool {
      fb.user == user;
    });
  };

  // ========== ADMIN METHODS ==========
  public shared ({ caller }) func clearOldFeedbacks(cutoffTimestamp : Int) : async () {
    assert(isAdmin(caller));
    feedbacks := Array.filter(feedbacks, func (fb : Feedback) : Bool {
      fb.timestamp >= cutoffTimestamp;
    });
  };

  // ========== PRIVATE HELPERS ==========
  func isAdmin(user : Principal) : Bool {
    // Replace with your admin principal IDs
    let admins = [
      Principal.fromText("YOUR-ADMIN-PRINCIPAL-ID-HERE")
    ];
    Array.find(admins, func (admin : Principal) : Bool { admin == user }) != null;
  };

  func adjustedMaxSubmissions(isPriority : Bool) : Nat {
    if (isPriority) { MAX_SUBMISSIONS_PER_WINDOW * 2 } // Allow more urgent reports
    else { MAX_SUBMISSIONS_PER_WINDOW }
  };
};