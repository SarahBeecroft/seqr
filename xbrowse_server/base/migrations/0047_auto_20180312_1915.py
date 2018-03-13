# -*- coding: utf-8 -*-
# Generated by Django 1.11 on 2018-03-12 19:15
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0046_project_disease_area'),
    ]

    operations = [
        migrations.AlterField(
            model_name='project',
            name='disease_area',
            field=models.TextField(blank=True, choices=[(b'blood', b'Blood'), (b'cardio', b'Cardio'), (b'kidney', b'Kidney'), (b'muscle', b'Muscle'), (b'neurodev', b'Neurodev'), (b'orphan_disease', b'Orphan Disease'), (b'retinal', b'Retinal')], null=True),
        ),
    ]