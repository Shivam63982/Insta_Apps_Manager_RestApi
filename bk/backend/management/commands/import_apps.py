import json
from django.core.management.base import BaseCommand
from backend.models import InstagramApp

class Command(BaseCommand):
    help = 'Import Instagram apps from JSON file'

    def handle(self, *args, **kwargs):
        with open('apps.json') as f:
            data = json.load(f)

        for item in data:
            app, created = InstagramApp.objects.get_or_create(
                app_id=item['app_id'],
                defaults={
                    'access_token': item['access_token'],
                    'name': item.get('name', '')
                }
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f"Added: {app.app_id}"))
            else:
                self.stdout.write(self.style.WARNING(f"Skipped existing: {app.app_id}"))
