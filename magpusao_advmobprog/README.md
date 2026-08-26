# Lab Activity 2: Discussion
The application fetches products from the DummyJSON API and displays them in a grid. Three enhancements were added: a search bar for filtering products, a details page that opens when a product card is selected, and a settings page containing the dark/light mode switch.
## Model, Service, and Screen Interaction
`ProductService` requests data from the API and converts the JSON response into `Product` models. `ProductScreen` uses `FutureBuilder` to handle loading, error, and successful states before displaying the products. The selected model is passed directly to `ProductDetailsScreen`.

Data flow:
`API -> ProductService -> Product model -> ProductScreen -> ProductDetailsScreen`
## Design Pattern
The project uses a layered Model-Service-Screen pattern. Models represent API data, services handle HTTP requests, screens manage the interface, and Provider controls the application-wide theme. This separation makes the code easier to understand and maintain.