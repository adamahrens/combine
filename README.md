# combine
Swift Combine work

# Publishers

Emit events (String, Int, [User]) over time

# Operators

Manipulate the events as they stream in

# Subscribers

Subscribe to a publisher to get the emitted events. Publishers never emit unless a Subscriber is listening.


# Subscription

Is the result of a publisher calling `subscribe` on a a Subscriber

There are two built-in operators you can use to subscribe to publishers: `sink(_:_:)` and `assign(to:on:)`.