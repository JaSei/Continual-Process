requires 'perl', '5.008001';
requires 'Class::Tiny';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception';
    recommends 'AnyEvent';
    recommends 'Mojo::IOLoop';
};

on 'develop' => sub {
    recommends 'Minilla';
};
