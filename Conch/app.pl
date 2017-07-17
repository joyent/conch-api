# Run with `carton exec perl app.pl`
use Dancer;

get '/hello/:name' => sub {
    return "Why, hello there " . param('name');
};

dance;

